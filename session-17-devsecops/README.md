# Session 17 — Complete CI/CD and DevSecOps

**Aman Kumar · Enrollment 10275**

The implemented path is **code → build → unit test → SAST → SCA → secret scan → Docker build → image scan → security gate → GHCR push → Kubernetes deployment**.

- [Application and tests](../final-devops-project/application)
- [Dockerfile](../final-devops-project/docker/Dockerfile)
- [Active workflow](../.github/workflows/devsecops.yml)
- [Security rules and gate policy](../final-devops-project/security/README.md)
- [Kubernetes manifests](../final-devops-project/kubernetes)
- [Pipeline evidence](../session-16-cicd/evidence/README.md)

## Gates and results

Semgrep scans application JavaScript with the upstream JavaScript ruleset and local rules. `npm audit` checks the locked dependency tree; this particular app uses only Node built-ins, so it has no third-party runtime packages. Trivy scans repository secrets and the full final container filesystem. HIGH/CRITICAL image findings block delivery even when the app dependency tree is empty.

The first real run demonstrated the gate working: [run 37800876628](https://github.com/ReaperXD67/devops-homework/actions/runs/37800876628) failed on vulnerable packages bundled with npm/Yarn in the base image. Publishing and deployment were skipped. The runtime never uses npm or Yarn, so the final Docker stage was reduced to exclude those unused package managers. Tests still run in the build stage. No ignore file or weakened severity threshold was used.

The subsequent run and saved reports on the evidence page show whether the repaired image passed. This before/after history is also a concrete DevSecOps troubleshooting example.

## Deployment and secrets

Successful main builds push a commit-tagged image to GHCR. The workflow deploys that exact tag to a fresh kind cluster and verifies `/healthz`, `/api/info` and `/metrics`. The cluster is discarded with the hosted runner. Local Minikube deployment is separately recorded in [the final project](../final-devops-project/README.md).

The runtime Secret is generated with a random value, masked in CI and created directly in Kubernetes. The checked-in Secret file is a template, not a credential. Workload controls include a non-root UID, dropped capabilities, read-only root filesystem, resource requests/limits and health probes. These reduce attack surface but do not guarantee an application is secure.

## Reproduce

Run the workflow from the GitHub Actions tab, or push an application change. Inspect each gate, download the evidence artifact, and confirm the deployed API returns enrollment 10275. A failure should be corrected in source or dependencies before retrying. AWS deployment is intentionally deferred until the account setup requested by the student is complete.

Sources: [Semgrep](https://semgrep.dev/docs/), [Trivy](https://trivy.dev/latest/docs/), [GitHub container publishing](https://docs.github.com/en/actions/use-cases-and-examples/publishing-packages/publishing-docker-images).
