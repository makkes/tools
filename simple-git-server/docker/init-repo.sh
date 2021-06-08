#!/bin/bash

set -euxo pipefail

if [[ -d /srv/git/repo ]]; then
  echo "Repo is already initialized."
  exit
fi

echo "Initialize Git Repository"

mkdir -p /srv/git/repo
cd /srv/git/repo
git init --bare
git symbolic-ref HEAD refs/heads/main
git clone /srv/git/repo /tmp/repo
cd /tmp/repo
git checkout -b main
mv /tmp/content/* .
git config user.email max@e13.dev
git config user.name max
git add .
git commit -m "initial commit"
git push --set-upstream origin main
chmod -R go+w /srv/git
