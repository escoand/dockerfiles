#!/bin/sh

#TMP=$(mktemp -d)
#TMP2=$(mktemp -d)
TMP=$PWD/.tmp
TMP2=$PWD/.tmp2
PATH=$PATH:$PWD/filesystem/usr/local/bin

# shellcheck disable=SC2064
#trap "rm -fr '$TMP' '$TMP2'" EXIT

cd "$TMP"

git init .
mkdir quadlet

# first commit
touch "$TMP/quadlet/test1.service"
touch "$TMP/quadlet/test2.service"
git add -A
git commit -am "initial"

# first run
REPO=$TMP REPOBRANCH=master LOCAL="$TMP2" \
	sh quadlet-sync.sh
