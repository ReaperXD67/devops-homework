#!/usr/bin/env bash
# Read-only checks to run as root through SSM after cloud-init finishes.
set -euo pipefail
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
grep BOOTSTRAP_COMPLETE /var/log/scaler-cloud-bootstrap.log
systemctl is-active k3s
kubectl get nodes -o wide
kubectl -n kube-system get deployment traefik metrics-server
flux get sources git -A
flux get helmreleases -A
helm list -n cloud-final
kubectl -n cloud-final get deployment,pod,service,ingress,hpa -o wide
kubectl -n cloud-final get deployment cloud-app -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
# Metrics Server can be Ready before its first usable sample exists.
metrics_ready=false
for attempt in $(seq 1 12); do
  if kubectl -n cloud-final top pods; then
    metrics_ready=true
    break
  fi
  printf 'Waiting for Metrics Server samples (attempt %s/12)\n' "$attempt"
  if [ "$attempt" -lt 12 ]; then sleep 5; fi
done
if [ "$metrics_ready" != true ]; then
  echo 'FAILED: Metrics Server did not provide Pod metrics within the warm-up window.'
  exit 1
fi
curl --fail http://127.0.0.1/healthz
curl --fail http://127.0.0.1/readyz
curl --fail http://127.0.0.1/metrics | sed -n '1,15p'
kubectl -n cloud-final exec -i deployment/cloud-app -- node <<'NODE'
const expectedAlerts = ["ApplicationDown", "HighApplicationMemory"];
const endpoints = {
  targets: "targets",
  up: "query?query=" + encodeURIComponent('up{job="devops-app"}'),
  rules: "rules",
  alerts: "alerts",
};
const requireCondition = (condition, message) => {
  if (!condition) throw new Error(message);
};

async function verifyMonitoring() {
  const deadline = Date.now() + 120000;
  let attempt = 0;
  let lastError;
  while (Date.now() < deadline) {
    attempt += 1;
    try {
      const responses = Object.fromEntries(await Promise.all(
        Object.entries(endpoints).map(async ([name, endpoint]) => {
          const timeout = Math.max(1, Math.min(5000, deadline - Date.now()));
          const response = await fetch("http://prometheus:9090/api/v1/" + endpoint, {
            signal: AbortSignal.timeout(timeout),
          });
          requireCondition(response.ok, name + " returned HTTP " + response.status);
          const body = await response.json();
          requireCondition(body.status === "success", name + " API status was not success");
          return [name, body.data];
        })
      ));

      const targets = responses.targets.activeTargets.filter(target => target.labels.job === "devops-app");
      requireCondition(targets.length >= 2, "Expected at least two application scrape targets; found " + targets.length);
      requireCondition(targets.every(target => target.health === "up"), "An application scrape target is not healthy");
      const samples = responses.up.result;
      requireCondition(Array.isArray(samples) && samples.length > 0, "The application up query returned no samples");
      requireCondition(samples.every(sample => sample.value && Number(sample.value[1]) === 1), "An application up sample is not 1");
      const rules = responses.rules.groups.flatMap(group => group.rules);
      requireCondition(expectedAlerts.every(name => rules.some(rule => rule.name === name)), "An expected alert rule is missing");

      // Print only relevant API fields: full discovery metadata can exceed SSM's
      // response limit and does not improve this verification evidence.
      console.log("targets", JSON.stringify({
        count: targets.length,
        healthy: targets.filter(target => target.health === "up").length,
        items: targets.map(target => ({ instance: target.labels.instance, health: target.health, lastError: target.lastError })),
      }));
      console.log("up", JSON.stringify(samples.map(sample => ({
        instance: sample.metric.instance, pod: sample.metric.pod, value: sample.value[1],
      }))));
      console.log("rules", JSON.stringify(rules.filter(rule => expectedAlerts.includes(rule.name)).map(rule => ({
        name: rule.name, state: rule.state, health: rule.health,
      }))));
      console.log("alerts", JSON.stringify({
        count: responses.alerts.alerts.length,
        items: responses.alerts.alerts.map(alert => ({ name: alert.labels.alertname, state: alert.state })),
      }));
      console.log("PASS: Prometheus APIs succeeded, at least two targets are healthy, all returned up samples are 1, and both alert rules exist.");
      return;
    } catch (error) {
      lastError = error;
      console.log("Monitoring warm-up attempt " + attempt + ": " + error.message);
      const remaining = deadline - Date.now();
      if (remaining > 0) await new Promise(resolve => setTimeout(resolve, Math.min(5000, remaining)));
    }
  }
  throw new Error("Monitoring verification did not pass within 120 seconds: " + lastError.message);
}
verifyMonitoring().catch(error => { console.error(error.message); process.exitCode = 1; });
NODE
printf 'READ_ONLY_CLOUD_CHECKS_COMPLETE\n'
