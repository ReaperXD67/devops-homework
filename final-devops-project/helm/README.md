# Final application Helm chart

**Aman Kumar · Enrollment 10275**

This chart deploys the final Node.js application with two replicas, a ClusterIP Service, ConfigMap, runtime Secret reference, health probes and a restricted container security context. Optional templates provide an Nginx Ingress and CPU-based HPA.

**Verified on the local Minikube cluster:** installation, two ready replicas, HTTP through the Service, Helm test, configuration upgrade from `APP_VERSION=1.0.0` to `1.1.0`, then rollback to `1.0.0`. The local run used `devops-final:local` loaded from the repository's Docker build. The default chart image is `ghcr.io/reaperxd67/devops-homework:latest`; the local evidence does not claim a registry pull or AWS deployment.

| Evidence | What it proves |
| --- | --- |
| [deployment.txt](evidence/deployment.txt) | Actual install, HTTP responses, upgrade, rollback, successful test logs and 2/2 deployment readiness |
| [lint.txt](evidence/lint.txt) | Helm chart lint result |
| [rendered.yaml](evidence/rendered.yaml) | Rendered manifests including optional Ingress/HPA; configuration, not execution output |
| [server-dry-run.txt](evidence/server-dry-run.txt) | Kubernetes API accepted the optional manifests in dry-run mode |
| [invalid-hpa-rejected.txt](evidence/invalid-hpa-rejected.txt) | Template rendering rejects minReplicas greater than maxReplicas |

## Chart behavior

The container listens on 8080; the Service exposes port 80. `/healthz` is the startup/liveness endpoint and `/readyz` is the readiness endpoint. Resource requests support CPU HPA calculation. The process runs as UID/GID 1000 with a read-only root filesystem, no privilege escalation, all capabilities dropped and RuntimeDefault seccomp. `/tmp` uses `emptyDir` because the application is stateless.

The ConfigMap exposes `APP_VERSION` and `PORT`; a checksum annotation rolls Pods when configuration changes. `DEMO_TOKEN` comes from key `token` of existing Secret `app-secret`. No token is stored in the chart or evidence. Service-account token mounting is disabled because the application does not call Kubernetes APIs.

When HPA is enabled, the Deployment omits `replicas` so Helm does not continually reset the autoscaler's desired count. An Ingress requires a running controller for class `nginx`; HPA requires metrics-server. Optional templates were accepted by the Kubernetes API in a dry run; this chart's recorded deployment leaves both disabled.

## Reproduce the local workflow

Build and load `devops-final:local` using the final project's Docker instructions, then run from the repository root with `helm`, `kubectl` and the `devops-homework` context available:

```powershell
./final-devops-project/helm/deploy-local.ps1
```

The script creates only the dedicated `devops-final-helm` namespace and its release resources, generates a token at runtime, installs the chart, checks HTTP, upgrades configuration and rolls back. It records native command output without exposing the token. The raw manifests use a separate namespace, `devops-final`.

For a direct installation using the default published image, first create the namespace and supply a runtime Secret through your secret manager or local CLI, then:

```powershell
helm lint final-devops-project/helm --strict
helm template final-app final-devops-project/helm -n devops-final-helm
helm upgrade --install final-app final-devops-project/helm -n devops-final-helm --wait --atomic
helm test final-app -n devops-final-helm --logs
helm list -n devops-final-helm
helm status final-app -n devops-final-helm
helm get values final-app -n devops-final-helm
helm history final-app -n devops-final-helm
kubectl -n devops-final-helm port-forward svc/final-app 18081:80
# In another terminal:
Invoke-WebRequest http://127.0.0.1:18081/api/info
```

Use a versioned image tag or digest for a long-lived deployment instead of relying on a mutable `latest` tag. The existing-secret requirement avoids storing confidential data in Helm values and release history.

## Upgrade and rollback

```powershell
helm upgrade final-app final-devops-project/helm -n devops-final-helm --reuse-values --set-string appVersion=1.1.0 --wait --atomic
helm history final-app -n devops-final-helm
helm rollback final-app 1 -n devops-final-helm --wait
helm test final-app -n devops-final-helm --logs
```

The recorded `/api/info` body changed `1.0.0 → 1.1.0 → 1.0.0`, verifying behavior beyond Helm's release status. `helm history` shows chart metadata `appVersion=1.0.0` throughout because this exercise changes a runtime configuration value rather than packaging a new chart version.

## Troubleshooting lesson

The initial test hook succeeded but used `hook-succeeded` deletion. Helm 3.19's `helm test --logs` then attempted to read a Pod that had already been removed and returned an error. [Actual before-fix evidence](evidence/test-log-before-fix.txt). The hook now uses `before-hook-creation`, retaining its completed Pod until the next test so logs can be read. The final evidence shows the successful readiness response and exit code 0.

## Cleanup

```powershell
helm uninstall final-app -n devops-final-helm --wait
kubectl delete namespace devops-final-helm
```

The namespace removal also removes the separately managed runtime Secret and retained completed test Pod. [Helm templates](https://helm.sh/docs/chart_template_guide/), [lint](https://helm.sh/docs/helm/helm_lint/) and [upgrade](https://helm.sh/docs/helm/helm_upgrade/) describe the packaging and release commands used here.
