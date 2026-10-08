#!/usr/bin/env bash
set -euo pipefail

current_date=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
machine_hostname=$(hostname)
current_user=$(id -un)

echo "Current date (UTC): $current_date"
echo "Hostname: $machine_hostname"
echo "Username: $current_user"
echo 'Disk usage:'
df -h

read -r -p 'Enter the directory in which to save process information: ' output_dir
# Accept CRLF input when the script is driven from PowerShell.
output_dir=${output_dir%$'\r'}
if [[ -z "$output_dir" ]]; then
  echo 'The output directory cannot be empty.' >&2
  exit 1
fi
mkdir -p -- "$output_dir"
process_file="$output_dir/running-processes.txt"
touch -- "$process_file"
ps aux > "$process_file"
echo 'Running processes:'
cat -- "$process_file"
echo "Process information saved to: $process_file"
