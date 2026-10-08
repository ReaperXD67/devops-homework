#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C TZ=UTC
PS4='+ '
set -x
date -u
git --version
lab_dir=$(mktemp -d /tmp/git-homework.XXXXXX)
cd "$lab_dir"
git init -b main
git config user.name 'Aman'
git config user.email 'reaperxd67@users.noreply.github.com'
git config commit.gpgsign false

printf 'Initial tracked file\n' > tracked.txt
git add tracked.txt
git commit -m 'main 1: add tracked file'

# -m supplies only the message: unstaged changes are not committed.
printf 'Manual staging demonstration\n' >> tracked.txt
if git commit -m 'This must fail: change is unstaged'; then exit 1; else echo 'Expected: git commit -m does not stage the modified file.'; fi
git add tracked.txt
git commit -m 'main 2: explicitly stage tracked change'

# -a stages modifications/deletions to tracked files, but not new files.
printf 'Automatically staged tracked change\n' >> tracked.txt
printf 'New untracked file\n' > new.txt
git status --short
git commit -a -m 'main 3: auto-stage tracked modification'
git status --short
git ls-files
git add new.txt
git commit -m 'main 4: explicitly add new file'
git log --oneline main

git switch -c topic
printf 'Not selected\n' > topic-one.txt
git add topic-one.txt
git commit -m 'topic 1: independent first feature'
printf 'The selected cherry-picked feature\n' > selected.txt
git add selected.txt
git commit -m 'topic 2: selected feature'
selected_commit=$(git rev-parse HEAD)
printf 'Also not selected\n' > topic-three.txt
git add topic-three.txt
git commit -m 'topic 3: independent third feature'
git log --oneline topic

git switch main
git cherry-pick "$selected_commit"
git log --oneline --graph --all --decorate
git show --stat HEAD
cat selected.txt
test ! -e topic-one.txt
test ! -e topic-three.txt
git status --short
echo 'Verified: only the selected topic change was applied to main.'
echo 'Temporary demonstration repository:' "$lab_dir"
