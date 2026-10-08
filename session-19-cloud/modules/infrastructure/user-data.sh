#!/usr/bin/env bash
set -euo pipefail
dnf install -y nginx
cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="en"><meta charset="utf-8"><title>Scaler Terraform lab</title>
<h1>Hello World from Terraform on AWS</h1>
<p>Aman Kumar · Enrollment 10275 · Session 19</p>
<p>VPC → subnet → security group → EC2. Artifacts use a private S3 bucket.</p>
</html>
HTML
printf 'ok\n' > /usr/share/nginx/html/health
systemctl enable --now nginx
