"""Build readable HTML excerpts from real saved logs for browser screenshots."""
from pathlib import Path
import html
import re

root = Path(__file__).resolve().parents[1]
out = root / 'output' / 'evidence-pages'
out.mkdir(parents=True, exist_ok=True)
sources = {
    'session-01-02-evidence': ('Linux links and users', 'session-01-02-linux/evidence/linux-output.txt'),
    'session-03-evidence': ('Shell scripting', 'session-03-shell/evidence/output.txt'),
    'session-04-evidence': ('Networking commands', 'session-04-networking/evidence/output.txt'),
    'session-05-evidence': ('Git commits and cherry-pick', 'session-05-git/evidence/output.txt'),
    'session-06-evidence': ('Six running Docker applications', 'session-06-docker/evidence/state.txt'),
    'session-07-evidence': ('Multi-stage image on port 8080', 'session-07-images/evidence/state.txt'),
    'session-08-evidence': ('Docker connectivity and isolation', 'session-08-networking/evidence/summary.txt'),
    'session-09-evidence': ('Kubernetes fundamentals', 'session-09-kubernetes/evidence/run.txt'),
    'session-10-evidence': ('Deployment strategies and Pod lifecycle', 'session-10-deployments/evidence/run.txt'),
    'session-11-evidence': ('Kubernetes Services and DNS', 'session-11-services/evidence/run.txt'),
    'session-12-evidence': ('ConfigMaps, Secrets and Ingress', 'session-12-config-ingress/evidence/run.txt'),
    'session-13-evidence': ('Storage and real HPA scaling', 'session-13-storage-hpa/evidence/run.txt'),
    'session-14-evidence': ('Kubernetes troubleshooting recovery', 'session-14-troubleshooting/evidence/run.txt'),
    'session-15-evidence': ('Helm upgrades and rollback', 'session-15-helm/evidence/run.txt'),
    'session-18-evidence': ('Terraform S3 validation — mock provider', 'session-18-terraform/evidence/validation.txt'),
    'session-19-evidence': ('Terraform cloud validation — mock provider', 'session-19-cloud/evidence/validation.txt'),
    'gitops-evidence': ('Flux automatically repairs live drift', 'final-devops-project/gitops/evidence/drift.txt'),
    'final-helm-evidence': ('Final application Helm lifecycle', 'final-devops-project/helm/evidence/deployment.txt'),
    'final-troubleshooting-evidence': ('Final application failure recovery', 'final-devops-project/troubleshooting/evidence/output.txt'),
    'monitoring-alert-evidence': ('Prometheus alert firing and recovery', 'final-devops-project/monitoring/evidence/run.txt'),
}
ansi = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]')
for slug, (title, source) in sources.items():
    path = root / source
    if not path.exists():
        print('Pending:', source)
        continue
    text = path.read_text(encoding='utf-8-sig', errors='replace')
    lines = [ansi.sub('', line).rstrip() for line in text.splitlines() if line.strip()]
    excerpt = '\n'.join(lines[-52:])
    page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><title>{html.escape(title)}</title>
<style>body{{margin:0;padding:28px;background:#f4f6f8;color:#15222c;font-family:system-ui}}small{{color:#4c6473}}h1{{font-size:27px;margin:10px 0}}p{{font-size:14px}}pre{{background:white;border:1px solid #cad4db;padding:18px;font:12px/1.45 Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;border-radius:6px}}a{{color:#07688b}}</style>
<small>AMAN KUMAR · ENROLLMENT 10275 · DEVOPS HOMEWORK</small>
<h1>{html.escape(title)}</h1><p>Browser rendering of a real saved command transcript, shown as an excerpt. No expected output has been substituted.</p>
<p>Source: <a href="../../{source}">{source}</a> · Last {min(52,len(lines))} nonempty lines of {len(lines)}</p>
<pre>{html.escape(excerpt)}</pre></html>'''
    (out / (slug + '.html')).write_text(page, encoding='utf-8')
print('Rendered evidence pages:', len(list(out.glob('*.html'))))
