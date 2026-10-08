#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C TZ=UTC
PS4='+ '
set -x
date -u
cat /etc/os-release
lab_dir=$(mktemp -d /tmp/linux-homework.XXXXXX)
cd "$lab_dir"

# A hard link shares an inode; a symbolic link stores a path.
printf 'Linux links demonstration\n' > original.txt
ln original.txt hard.txt
ln -s original.txt soft.txt
ls -li original.txt hard.txt soft.txt
stat -c '%n inode=%i links=%h type=%F' original.txt hard.txt soft.txt
cat soft.txt hard.txt
rm original.txt
cat hard.txt
if cat soft.txt; then exit 1; else echo 'Expected: symbolic link is dangling after original path removal.'; fi
printf 'Content survives through hard link: '; cat hard.txt
rm soft.txt hard.txt
ls -la

# This account exists only inside the disposable container.
adduser --disabled-password --gecos 'Homework test user' studentdemo
id studentdemo
getent passwd studentdemo
ls -ld /home/studentdemo
deluser --remove-home studentdemo
if id studentdemo; then exit 1; else echo 'Verified: disposable test account removed.'; fi

# Ubuntu containers have journalctl installed but no systemd journal.
journalctl --version | head -n 1
journalctl --no-pager -n 5
journalctl -u ssh.service --no-pager -n 5

# File, permissions, filtering, process and resource exercises.
mkdir notes
touch notes/empty.txt
printf 'linux\ndocker\nlinux\nkubernetes\n' > notes/topics.txt
pwd
ls -lah notes
cp notes/topics.txt notes/copy.txt
mv notes/copy.txt notes/renamed.txt
cat notes/topics.txt
head -n 2 notes/topics.txt
tail -n 2 notes/topics.txt
grep -n linux notes/topics.txt
sort notes/topics.txt | uniq -c
wc -l notes/topics.txt
find notes -type f -name '*.txt'
chmod 640 notes/renamed.txt
ls -l notes/renamed.txt
du -sh notes
df -h /
free -m
ps -eo pid,comm,args | head -n 10
uname -srm
whoami
id
rm notes/empty.txt notes/renamed.txt notes/topics.txt
rmdir notes
cd /
rmdir "$lab_dir"
echo 'Linux exercises completed successfully.'
