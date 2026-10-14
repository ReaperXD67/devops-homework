# Application monitoring

Run `docker compose up -d --build` here. The application is available at http://localhost:8200 and Prometheus at http://localhost:9090. Run `powershell -ExecutionPolicy Bypass -File verify.ps1` for the controlled outage/recovery demonstration.

The [Session 20 README](../../session-20-observability/README.md) explains metrics, logs, traces, CPU/memory queries, alerts, and GitOps. [Actual alert transcript](evidence/run.txt) records the firing alert and recovery; [state output](evidence/state.txt) includes live metrics and JSON logs. A local scrape runs every five seconds and only one hour of time-series data is retained.

The Compose demo provides reproducible local outage and recovery evidence; Kubernetes resource metrics and probes are separately shown in [local Kubernetes evidence](../kubernetes/evidence/state.txt). A production setup would add authenticated access, persistent storage and alert routing.

The [AWS final deployment](../terraform/README.md) was verified on 14 October 2026 with namespace-scoped Kubernetes Pod discovery. Prometheus reported two healthy application targets with `up=1`; `ApplicationDown` and `HighApplicationMemory` were inactive. Kubernetes returned Pod CPU/memory usage, and both application replicas were Ready. See the [actual cloud transcript](../terraform/evidence/aws-live.txt). This cloud verification checks healthy scraping, rule evaluation and resource metrics; the deliberate outage/firing/recovery and HPA load experiments are documented by their local transcripts.

The ephemeral AWS environment was then destroyed: 20 Terraform resources removed, state empty, instances terminated, VPC and bucket absent, and no remaining tagged lab EBS volumes. The cloud transcript records that cleanup; the AWS application and Prometheus endpoints are no longer running.

Cleanup: `docker compose down`. This only removes the monitoring project's containers/network.
