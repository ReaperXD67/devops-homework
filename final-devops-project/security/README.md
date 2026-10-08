# Security gates

The workflow stops on failed unit tests, Semgrep findings, vulnerable dependencies reported by `npm audit`, detected secrets, or HIGH/CRITICAL container vulnerabilities.

| Stage | Tool | Scope |
|---|---|---|
| SAST | Semgrep | JavaScript recommended rules plus local rules prohibiting eval/shell execution |
| SCA | npm audit | npm lockfile; the final app deliberately has no third-party runtime dependencies |
| Secret scan | Trivy filesystem secret scanner | repository source; runtime values are excluded from Git |
| Image scan | Trivy | OS and language packages in the final image |

An empty dependency tree is explicitly not a substitute for checking the operating system image. All image findings at the configured severity block publishing. The container runs as UID 1000, drops capabilities, uses a read-only filesystem and HTTP probes. The Kubernetes Secret is generated during deployment and never printed or committed. GitHub Actions uses its short-lived `GITHUB_TOKEN` for GHCR; no personal access token is stored in the workflow.

Custom SAST rules are a small additional policy, not comprehensive proof of security. The workflow also uses the upstream JavaScript ruleset. Reports are uploaded even if a gate fails.

Sources: [Semgrep CLI](https://semgrep.dev/docs/cli-reference), [Trivy scanning](https://trivy.dev/latest/docs/), [npm audit](https://docs.npmjs.com/cli/v11/commands/npm-audit).
