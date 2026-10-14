"""Render selected real AWS log lines for clearly labeled evidence screenshots."""
from pathlib import Path
import html
import re
ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "session-18-aws": ("Session 18: live AWS S3 lifecycle", "session-18-terraform/evidence/aws-live.txt"),
    "session-19-aws": ("Session 19: live AWS network and EC2", "session-19-cloud/evidence/aws-live.txt"),
    "final-cloud-aws": ("Final project: AWS Kubernetes, Helm and Flux", "final-devops-project/terraform/evidence/aws-live.txt"),
}
patterns = re.compile(r"Apply complete!|Destroy complete!|No changes\.|Plan:|Status.*Enabled|SSEAlgorithm|PublicAcls|PublicPolicy|IgnorePublic|RestrictPublic|ObjectOwnership|BOOTSTRAP_COMPLETE|Hello World from Terraform|HTTP/1\.|\"status\":\"ok|\"version\"|running|terminated|404|State.*Name|Success|Ready|deployed|up.*1|Exit code:|^UTC |^\$.*(?:state list|health|output|describe-instance|describe-vpcs|head-bucket)")
for slug, (title, relative) in SOURCES.items():
    source = ROOT / relative
    if not source.exists():
        continue
    lines = [x for x in source.read_text(encoding="utf-8").splitlines() if len(x) < 500 and patterns.search(x)]
    # Drop generic exit markers; command timestamps and actual outcomes stay visible.
    lines = [x for x in lines if not x.startswith("Exit code:")]
    if slug == "final-cloud-aws":
        important = re.compile(r"BOOTSTRAP_COMPLETE|READ_ONLY_CLOUD_CHECKS_COMPLETE|AUTOMATIC_FLUX|^Immediately|observed APP_VERSION|^targets |^up |^rules |^PASS: Prometheus|^HTTP/1.1 200|^\{\"application\"|^Destroy complete|^.*control-plane.*Ready|^.*Ready.*control-plane|^deployment.apps/(?:cloud-app|prometheus)|^\s*\"State\": \"terminated|^\$.*(?:state list|describe-vpcs|describe-volumes|head-bucket)|^\[\]$|404.*Not Found")
        content = source.read_text(encoding="utf-8")
        completed_bootstrap = content.rfind("\nstatus: done\n")
        if completed_bootstrap >= 0:
            content = content[completed_bootstrap:]
        lines = [line for line in content.splitlines() if len(line) < 500 and important.search(line)]
    excerpt = "\n".join(lines[-65:])
    page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><title>{html.escape(title)}</title>
<style>body{{margin:0;padding:26px;background:#f4f6f8;color:#15222c;font-family:system-ui}}h1{{font-size:26px}}small,p{{font-size:13px}}pre{{background:white;border:1px solid #cad4db;border-radius:6px;padding:18px;font:12px/1.42 Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere}}</style>
<small>AMAN KUMAR · ENROLLMENT 10275 · VERIFIED 14 OCTOBER 2026</small><h1>{html.escape(title)}</h1>
<p>Selected verbatim lines from real command output. Account ID and learner IP are redacted. This is a browser rendering of a transcript, not an AWS Console screenshot.</p>
<p>Full source: {html.escape(relative)}</p><pre>{html.escape(excerpt)}</pre></html>'''
    destination = ROOT / "output/evidence-pages" / (slug + ".html")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(page, encoding="utf-8")
    print(destination.relative_to(ROOT))
