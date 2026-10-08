# Session 20: GitOps hands-on

The shared [Flux GitOps implementation](../../final-devops-project/gitops/README.md) contains the YAML, setup, concepts, troubleshooting and real evidence for this session.

The experiment tracks the public repository's `main` branch and continuously reconciles a ConfigMap into an isolated Minikube namespace. It then changes the live value manually and watches Flux restore the committed value automatically. No GitHub credentials are needed to read this public repository.

**Verified on 8 October 2026:** Flux fetched commit `fc117d49`, both controllers became Ready, and manual drift was automatically restored to `Git is the source of truth`. The changed value was observed at `15:32:47.068Z`; the restored value was observed at `15:32:52.169Z`, with the intervening controller apply recorded in its logs.

| Requirement | Evidence |
|---|---|
| Git as source of truth | [GitRepository](../../final-devops-project/gitops/source.yaml) |
| Declarative configuration | [Desired ConfigMap](../../final-devops-project/gitops/desired/configmap.yaml) |
| Continuous reconciliation | [30-second Flux Kustomization](../../final-devops-project/gitops/reconcile.yaml) |
| GitOps workflow and Kubernetes | [Architecture and setup](../../final-devops-project/gitops/README.md) |
| Controller deployment | [Installation transcript](../../final-devops-project/gitops/evidence/installation.txt) |
| Drift detection and correction | [Verification script](../../final-devops-project/gitops/verify-drift.ps1) and [actual output](../../final-devops-project/gitops/evidence/drift.txt) |
| Complete final application delivery | [Active reconciliation](../../final-devops-project/gitops/final-app.yaml) and [HTTP-verified handoff](../../final-devops-project/gitops/evidence/final-app-handoff.txt) |

The final application's handoff was also completed: Flux pulled commit `f49214ee`, deployed the public image pinned by digest, and reported Ready. Both `/healthz` and `/api/info` returned HTTP 200 through the Kubernetes Service. Its runtime Secret remains externally supplied rather than stored in Git.
