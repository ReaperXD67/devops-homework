# DevOps homework - Aman Kumar

**Enrollment:** 10275 | **GitHub:** [ReaperXD67](https://github.com/ReaperXD67)

One public repository for all course sessions, with source code, scripts, Dockerfiles, Kubernetes manifests, Helm charts, Terraform projects, actual command output and screenshots.

**Non-AWS work is implemented and demonstrated locally and in GitHub Actions. Live AWS provisioning is pending account setup, as requested.** Terraform formatting, validation and seven mock-provider tests have passed; mock tests are not cloud execution.

[AWS setup instructions](session-18-terraform/AWS-SETUP.md) | [Final project](final-devops-project/README.md) | [Successful CI/CD run](https://github.com/ReaperXD67/devops-homework/actions/runs/37801380225)

## Submission README links

Paste the corresponding **README file link** below into each session field in the submission form. All links belong to this single public repository.

| Session | GitHub README file | Evidence / status |
|---|---|---|
| 1 & 2 - Linux fundamentals | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-01-02-linux/README.md) | Links, test user, logs and command practice |
| 3 - Shell scripting | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-03-shell/README.md) | Executed system-information script |
| 4 - Networking fundamentals | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-04-networking/README.md) | Real network commands and explanations |
| 5 - Git/GitHub | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-05-git/README.md) | Commit staging and selective cherry-pick |
| 6 - Docker fundamentals | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-06-docker/README.md) | Six built/running Hello World applications |
| 7 - Docker images | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-07-images/README.md) | Multi-stage build on port 8080 |
| 8 - Docker networking | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-08-networking/README.md) | Networks, Apache host mode, bind mount, overlay research |
| 9 - Kubernetes fundamentals | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-09-kubernetes/README.md) | Minikube and tutorial workflow |
| 10 - Pods, ReplicaSets & Deployments | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-10-deployments/README.md) | Four strategies and Pod lifecycle |
| 11 - Kubernetes networking & Services | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-11-services/README.md) | Five Service patterns, FQDN and CoreDNS |
| 12 - Ingress, ConfigMaps & Secrets | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-12-config-ingress/README.md) | Configuration, runtime Secret and ingress routing |
| 13 - Storage, HPA & Probes | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-13-storage-hpa/README.md) | Persistence and actual load/autoscaling |
| 14 - Kubernetes troubleshooting | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-14-troubleshooting/README.md) | Faults, root causes, repairs and verification |
| 15 - Helm | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-15-helm/README.md) | Install, two upgrades, rollback and uninstall |
| 16 - CI/CD & GitHub Actions | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-16-cicd/README.md) | Successful hosted pipeline and preserved reports |
| 17 - CI/CD & DevSecOps | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-17-devsecops/README.md) | Security gates, registry and Kubernetes |
| 18 - Terraform & Infrastructure as Code | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-18-terraform/README.md) | S3 project + five AWS READMEs; live AWS pending |
| 19 - Cloud & Terraform | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-19-cloud/README.md) | Validated VPC/EC2/S3 project; live AWS pending |
| 20 - Monitoring, Observability & GitOps | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/session-20-observability/README.md) | Metrics/logs/alerts and Flux reconciliation |
| 21 - Final DevOps project | [README.md](https://github.com/ReaperXD67/devops-homework/blob/main/final-devops-project/README.md) | Integrated local/CI project; cloud stage pending |

## Evidence

Recorded on **8 October 2026** using Windows, WSL Ubuntu, Docker Desktop, Kubernetes v1.34.0 on a dedicated Minikube profile, Helm, Terraform, GitHub Actions, Prometheus and Flux. Each session links to runnable files and raw output.

Browser screenshots show real applications, GitHub Actions and Prometheus. Screenshots titled command transcript are browser-rendered excerpts of linked raw logs, created by [the evidence renderer](scripts/render_evidence.py); no expected output is substituted. Sensitive runtime values are excluded. The failed first image scan and successful remediation remain visible in Actions history.

![Successful GitHub Actions execution](output/playwright/github-actions-success.png)

## Assignment references and limits

The [assignment document](https://docs.google.com/document/d/1cjXFYf2Thm8cBEN-0C48B-v02cj3jGLd47lcO18prHE/edit) contains the requirements. Its linked `Nency-kRavaliya/Kubernetes` repository returned 404, and some named mini-projects/example repositories were not linked. Affected READMEs identify original equivalent exercises covering the written requirements; they do not claim access to unavailable instructor files.

AWS setup and actual `plan/apply/show/output/destroy` evidence are the remaining cloud work. Follow [AWS-SETUP.md](session-18-terraform/AWS-SETUP.md), configure the `scaler-lab` profile and verify `aws sts get-caller-identity`. No AWS credentials, live Terraform state or plan files belong in this public repository.
