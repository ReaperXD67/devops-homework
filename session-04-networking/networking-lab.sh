#!/usr/bin/env bash
set -uo pipefail
export LC_ALL=C TZ=UTC
run() {
  printf '\n$'; printf ' %q' "$@"; printf '\n'
  "$@" 2>&1
  result=$?
  printf '[exit status: %s]\n' "$result"
}
run date -u
run hostname
run ip -brief address
run ip route
run ip route get 1.1.1.1
run ping -c 3 -W 2 127.0.0.1
run ping -c 3 -W 2 example.com
run dig example.com A +noall +answer
run nslookup example.com
run getent ahostsv4 example.com
run cat /etc/resolv.conf
run curl --head --max-time 20 https://example.com
run wget --spider --timeout=20 https://example.com
run nc -vz -w 10 example.com 443
run ss -tunlp
run netstat -rn
run traceroute -m 5 -w 1 -q 1 example.com
printf '\nThe external route/ICMP results reflect this Docker Desktop network.\n'
