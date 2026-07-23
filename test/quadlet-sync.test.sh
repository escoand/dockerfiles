#!/bin/sh

TMP=$(mktemp -du)
LOG=$TMP/log
PATH=$TMP/bin:$PWD/filesystem/usr/local/bin:$PATH

# used by script
export REPO="$TMP/repo"
export LOCAL="$TMP/local"
export REPOBRANCH=master
export REPODIR=quadlet

# used by git
export GIT_COMMITTER_NAME=dummy
export GIT_COMMITTER_EMAIL=dummy@example.com
export GIT_AUTHOR_NAME=$GIT_COMMITTER_NAME
export GIT_AUTH_MAIL=$GIT_COMMITTER_EMAIL

oneTimeSetUp() {
	# setup repo
	git init -q "$REPO"
	mkdir "$REPO/$REPODIR"

	# mock systemctl
	mkdir "$TMP/bin"
	# shellcheck disable=SC2016
	echo 'echo "@@ MOCK @@ ${0##*/} $@"' >"$TMP/bin/systemctl"
	chmod +x "$TMP/bin/systemctl"
}

oneTimeTearDown() {
	rm -fr "$TMP"
}

# first commit
testIntial() {
	touch "$REPO/$REPODIR/test1.container"
	touch "$REPO/$REPODIR/test2.container"
	git -C "$REPO" add -A
	git -C "$REPO" commit -aqm "initial"

	quadlet-sync.sh >"$LOG" 2>&1

	grep -Fq "Cloning into" "$LOG"
	assertEquals $LINENO $? 0
	grep -Fqx "@@ MOCK @@ systemctl --user start test1 test2" "$LOG"
	assertEquals $LINENO $? 0
}

# update commit
testChanges() {
	date >"$REPO/$REPODIR/test1.container"
	rm "$REPO/$REPODIR/test2.container"
	touch "$REPO/$REPODIR/test3.container"
	git -C "$REPO" add -A
	git -C "$REPO" commit -aqm "update"

	quadlet-sync.sh >"$LOG" 2>&1

	grep -Fq "Fast-forward" "$LOG"
	assertEquals $LINENO $? 0
	grep -Fqx "@@ MOCK @@ systemctl --user stop test2" "$LOG"
	assertEquals $LINENO $? 0
	grep -Fq "@@ MOCK @@ systemctl --user try-restart test1 test3" "$LOG"
	assertEquals $LINENO $? 0
}

# no changes
testNoChanges() {
	quadlet-sync.sh >"$LOG" 2>&1

	grep -Fq "Already up to date." "$LOG"
	assertEquals $LINENO $? 0
	grep -Fqx "@@ MOCK @@ systemctl --user daemon-reload" "$LOG"
	assertEquals $LINENO $? 0
	grep -Fq -e "@@ MOCK @@ systemctl --user try-restart" -e "@@ MOCK @@ systemctl --user stop" "$LOG"
	assertNotEquals $LINENO $? 0
}

# shellcheck disable=SC1091
. shunit2
