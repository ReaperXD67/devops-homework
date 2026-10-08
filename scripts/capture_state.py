"""Capture genuine process output; never substitute expected output for results."""
from datetime import datetime, timezone
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def record(relative_path, commands, cwd=ROOT):
    target = ROOT / relative_path
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open('w', encoding='utf-8') as out:
        out.write('Captured UTC: ' + datetime.now(timezone.utc).isoformat() + '\n')
        for command in commands:
            out.write('\n$ ' + subprocess.list2cmdline(command) + '\n')
            result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, encoding='utf-8', errors='replace')
            out.write(result.stdout + result.stderr)
            out.write(f'\nExit code: {result.returncode}\n')
    print(target.relative_to(ROOT))


record('session-06-docker/evidence/state.txt', [
    ['docker', 'compose', '-f', 'session-06-docker/compose.yaml', 'ps'],
    ['docker', 'images', '--filter', 'reference=devops-hello-*'],
])
record('session-07-images/evidence/state.txt', [
    ['docker', 'ps', '--filter', 'name=devops-multistage'],
    ['curl.exe', '--fail', '--silent', 'http://127.0.0.2:8080'],
    ['docker', 'image', 'inspect', 'devops-multistage:1', '--format', 'Size={{.Size}} User={{.Config.User}}'],
    ['docker', 'history', 'devops-multistage:1'],
])
record('session-08-networking/evidence/summary.txt', [
    ['docker', 'network', 'ls', '--filter', 'name=devops-network'],
    ['docker', 'compose', '-f', 'session-08-networking/compose.yaml', 'exec', '-T', 'frontend', 'ping', '-c', '2', 'backend'],
    ['docker', 'compose', '-f', 'session-08-networking/compose.yaml', 'exec', '-T', 'backend', 'ping', '-c', '2', 'database'],
    ['docker', 'compose', '-f', 'session-08-networking/compose.yaml', 'exec', '-T', 'frontend', 'ping', '-c', '1', 'database'],
    ['docker', 'exec', 'devops-host-network-lab', 'docker', 'inspect', 'apache-host', '--format', '{{.HostConfig.NetworkMode}}'],
    ['docker', 'exec', 'devops-host-network-lab', 'wget', '-qO-', 'http://127.0.0.1:80'],
    ['curl.exe', '--fail', '--silent', 'http://127.0.0.1:8181'],
])
record('final-devops-project/kubernetes/evidence/state.txt', [
    ['kubectl', '--context', 'devops-homework', '-n', 'devops-final', 'get', 'pods,svc,ingress,hpa', '-o', 'wide'],
    ['kubectl', '--context', 'devops-homework', '-n', 'devops-final', 'top', 'pods'],
    ['kubectl', '--context', 'devops-homework', '-n', 'devops-final', 'exec', 'deployment/devops-app', '--', 'node', '-e', "fetch('http://localhost:8080/api/info').then(r=>r.text()).then(console.log)"],
    ['kubectl', '--context', 'devops-homework', '-n', 'devops-final', 'logs', 'deployment/devops-app', '--tail=8'],
])
record('final-devops-project/monitoring/evidence/state.txt', [
    ['docker', 'compose', '-f', 'final-devops-project/monitoring/compose.yaml', 'ps'],
    ['curl.exe', '--fail', '--silent', 'http://127.0.0.1:8200/metrics'],
    ['docker', 'compose', '-f', 'final-devops-project/monitoring/compose.yaml', 'logs', '--tail', '8', 'app'],
])
