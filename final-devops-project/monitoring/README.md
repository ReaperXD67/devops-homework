# Application monitoring

Run `docker compose up -d --build` here. The application is available at http://localhost:8200 and Prometheus at http://localhost:9090. Run `powershell -ExecutionPolicy Bypass -File verify.ps1` for the controlled outage/recovery demonstration.

The [Session 20 README](../../session-20-observability/README.md) explains metrics, logs, traces, CPU/memory queries, alerts, and GitOps. [Actual alert transcript](evidence/run.txt) records the firing alert and recovery; [state output](evidence/state.txt) includes live metrics and JSON logs. A local scrape runs every five seconds and only one hour of time-series data is retained.

The demo uses Compose for reproducible local monitoring; Kubernetes resource metrics and probes are separately shown in [Kubernetes evidence](../kubernetes/evidence/state.txt). A production setup would add authenticated access, persistent storage, alert routing and Kubernetes service discovery.

Cleanup: `docker compose down`. This only removes the monitoring project's containers/network.
