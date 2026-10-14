"""Offline bootstrap checks; requires PyYAML, Terraform, Helm, kubectl and Bash.

No AWS provider, state, credentials or Kubernetes API is accessed. A temporary
Terraform configuration evaluates only local values and input defaults.
"""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

import yaml


def run(command, **kwargs):
    result = subprocess.run(command, text=True, capture_output=True, check=True, **kwargs)
    return result.stdout


parser = argparse.ArgumentParser(description=__doc__)
for name in ("terraform", "helm", "kubectl", "bash"):
    parser.add_argument("--" + name, default=name)
args = parser.parse_args()
root = Path(__file__).resolve().parent
chart = root.parent / "helm"

with tempfile.TemporaryDirectory(prefix="scaler-bootstrap-check-") as temporary:
    work = Path(temporary)
    locals_hcl = (root / "main.tf").read_text(encoding="utf-8").split("# Separate state")[0]
    locals_hcl = locals_hcl.replace("${path.module}", root.as_posix())
    (work / "main.tf").write_text(locals_hcl, encoding="utf-8")
    (work / "variables.tf").write_text((root / "variables.tf").read_text(encoding="utf-8"), encoding="utf-8")
    encoded = run([args.terraform, "console", "-no-color"], cwd=work, input="jsonencode(local.bootstrap)\n")
    script = json.loads(json.loads(encoded))
    script_path = work / "bootstrap.sh"
    script_path.write_text(script, encoding="utf-8", newline="\n")
    size = len(script.encode("utf-8"))
    assert size <= 16384, f"EC2 user data exceeds limit: {size} bytes"
    run([args.bash, "--noprofile", "--norc", "-n", script_path.as_posix()])
    print(f"PASS: Terraform template rendering; Bash syntax; raw user data {size}/16384 bytes")

    # Exercise the real polling function with a fake API and no actual sleeps.
    registration = re.search(r"(?ms)^wait_for_node_registration\(\) \{\n.*?^\}", script)
    assert registration, "Missing bounded Node registration wait"
    assert script.index("\nwait_for_node_registration\n") < script.index("kubectl wait --for=condition=Ready node")
    polling_stub = r'''#!/usr/bin/env bash
set -euo pipefail
printf '0' > node-counter
kubectl() {
  local count
  count=$(cat node-counter)
  count=$((count + 1))
  printf '%s' "$count" > node-counter
  if [ "$count" -eq 1 ]; then return 1; fi
  if [ "$count" -ge "$READY_AFTER" ]; then printf 'node/mock\n'; fi
}
sleep() { :; }
'''
    for ready_after, checks in ((3, 'wait_for_node_registration\ntest "$(cat node-counter)" -eq 3'),
                                (999, 'if wait_for_node_registration; then exit 1; fi\ntest "$(cat node-counter)" -eq 60')):
        probe = work / "registration-probe.sh"
        probe.write_text(polling_stub + f"READY_AFTER={ready_after}\n" + registration.group(0) + "\n" + checks + "\n", encoding="utf-8", newline="\n")
        run([args.bash, "--noprofile", "--norc", probe.as_posix()], cwd=work)
    print("PASS: Node registration polling handles API startup failure, empty node list, later registration and bounded timeout")

    def heredoc(marker):
        match = re.search(r"<<'" + marker + r"'\n(.*?)\n" + marker + r"\n", script, re.S)
        assert match, f"Missing {marker} manifest"
        return list(yaml.safe_load_all(match.group(1)))

    k3s = heredoc("K3S")[0]
    assert k3s["cluster-cidr"] == "10.52.0.0/16"
    assert k3s["service-cidr"] == "10.53.0.0/16"
    assert k3s["cluster-dns"] == "10.53.0.10"
    application = heredoc("APPLICATION")
    release = next(doc for doc in application if doc["kind"] == "HelmRelease")
    monitoring = heredoc("MONITORING")
    configuration = next(doc for doc in monitoring if doc["kind"] == "ConfigMap")
    prometheus = yaml.safe_load(configuration["data"]["prometheus.yml"])
    rules = yaml.safe_load(configuration["data"]["alerts.yml"])
    assert prometheus["scrape_configs"][0]["kubernetes_sd_configs"][0]["namespaces"]["names"] == ["cloud-final"]
    assert len(rules["groups"][0]["rules"]) == 2
    assert release["spec"]["postRenderStrategy"] == "combined"
    print(f"PASS: YAML parsing ({len(application)} GitOps, {len(monitoring)} monitoring documents); network/discovery contracts")

    values = work / "values.yaml"
    values.write_text(yaml.safe_dump(release["spec"]["values"]), encoding="utf-8")
    print(run([args.helm, "lint", str(chart), "--strict", "-f", str(values)]).strip())
    # Flux Revision reconciliation appends SemVer build metadata to Chart.Version.
    # Kubernetes rejects '+' in labels, even though it is valid in SemVer.
    metadata_chart = work / "metadata-chart"
    shutil.copytree(chart, metadata_chart, ignore=shutil.ignore_patterns("evidence"))
    chart_metadata_path = metadata_chart / "Chart.yaml"
    chart_metadata = yaml.safe_load(chart_metadata_path.read_text(encoding="utf-8"))
    chart_metadata["version"] = chart_metadata["version"].split("+")[0] + "+ad0030e111ed"
    chart_metadata_path.write_text(yaml.safe_dump(chart_metadata), encoding="utf-8")
    metadata_render = run([args.helm, "template", "cloud-app", str(metadata_chart), "--namespace", "cloud-final", "-f", str(values)])
    label_values = []

    def validate_metadata_labels(node):
        if isinstance(node, list):
            for item in node:
                validate_metadata_labels(item)
        elif isinstance(node, dict):
            for key, value in node.get("metadata", {}).get("labels", {}).items():
                assert isinstance(value, str) and len(value) <= 63, f"Invalid label size/type: {key}={value!r}"
                assert value == "" or re.fullmatch(r"[A-Za-z0-9](?:[-A-Za-z0-9_.]*[A-Za-z0-9])?", value), f"Invalid label: {key}={value!r}"
                label_values.append((key, value))
            for value in node.values():
                validate_metadata_labels(value)

    validate_metadata_labels(list(yaml.safe_load_all(metadata_render)))
    chart_label = (chart_metadata["name"] + "-" + chart_metadata["version"]).replace("+", "_")[:63].removesuffix("-")
    assert ("helm.sh/chart", chart_label) in label_values
    print(f"PASS: Flux build-metadata chart {chart_metadata['version']}; {len(label_values)} valid metadata labels; helm.sh/chart={chart_label}")
    rendered = run([args.helm, "template", "cloud-app", str(chart), "--namespace", "cloud-final", "-f", str(values)])
    (work / "app.yaml").write_text(rendered, encoding="utf-8")
    images = release["spec"]["postRenderers"][0]["kustomize"]["images"]
    (work / "kustomization.yaml").write_text(yaml.safe_dump({
        "apiVersion": "kustomize.config.k8s.io/v1beta1", "kind": "Kustomization",
        "resources": ["app.yaml"], "images": images,
    }), encoding="utf-8")
    transformed = list(yaml.safe_load_all(run([args.kubectl, "kustomize", str(work)])))
    expected = images[0]["newName"] + "@" + images[0]["digest"]
    deployment = next(doc for doc in transformed if doc["kind"] == "Deployment")
    hook = next(doc for doc in transformed if doc["kind"] == "Pod")
    ingress = next(doc for doc in transformed if doc["kind"] == "Ingress")
    assert deployment["spec"]["template"]["spec"]["containers"][0]["image"] == expected
    assert hook["spec"]["containers"][0]["image"] == expected
    assert ingress["spec"]["ingressClassName"] == "traefik"
    assert ingress["spec"]["rules"][0].get("host", "") == ""
    assert deployment["spec"]["template"]["spec"]["securityContext"]["runAsUser"] == 1000
    print("PASS: Helm render, digest transformation for application and test hook, Traefik catch-all, non-root application")
    print("OFFLINE ONLY: no live cloud, bootstrap execution, PromQL evaluation or Kubernetes API validation is claimed.")
