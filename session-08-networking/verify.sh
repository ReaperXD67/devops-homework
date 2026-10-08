#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p evidence
exec > >(tee evidence/run.txt) 2>&1
set -x
date -u
docker compose up -d
docker network ls --filter name=devops-network
docker compose exec -T frontend ping -c 2 backend
docker compose exec -T backend ping -c 2 database
if docker compose exec -T frontend ping -c 1 database; then
  echo 'FAIL: isolated frontend resolved the database'; exit 1
else
  echo 'PASS: frontend cannot resolve database on its isolated network'
fi
docker inspect "$(docker compose ps -q backend)" --format '{{json .NetworkSettings.Networks}}'
# A nested, privileged Docker-in-Docker Linux host provides genuine host-network
# semantics without changing Docker Desktop host-network settings.
docker run -d --privileged --name devops-host-network-lab -p 127.0.0.1:8180:80 -e DOCKER_TLS_CERTDIR= docker:29-dind
for i in $(seq 1 60); do docker exec devops-host-network-lab docker info >/dev/null 2>&1 && break; sleep 2; done
docker exec devops-host-network-lab docker run -d --name apache-host --network host httpd:2.4-alpine
docker exec devops-host-network-lab docker inspect apache-host --format '{{.HostConfig.NetworkMode}}'
for i in $(seq 1 30); do docker exec devops-host-network-lab wget -qO- http://127.0.0.1:80 && break; sleep 2; done
curl --fail http://127.0.0.1:8180
docker run -d --name devops-bind-demo -p 127.0.0.1:8181:80 --mount "type=bind,source=$(pwd)/site,target=/usr/share/nginx/html,readonly" nginx:stable-alpine
sleep 2
curl --fail http://127.0.0.1:8181
before=$(docker inspect devops-bind-demo --format '{{.State.StartedAt}}')
printf '<!doctype html><h1>Hello students - updated without restart</h1>\n' > site/index.html
curl --fail http://127.0.0.1:8181
after=$(docker inspect devops-bind-demo --format '{{.State.StartedAt}}')
test "$before" = "$after"
echo "PASS: container StartedAt unchanged: $after"
printf '<!doctype html><html lang="en"><meta charset="utf-8"><title>Bind mount demo</title><h1>Hello students</h1></html>\n' > site/index.html
docker stats --no-stream $(docker compose ps -q)
