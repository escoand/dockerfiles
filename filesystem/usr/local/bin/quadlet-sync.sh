#!/bin/sh

set -eu

restart_units=$(mktemp)
stop_units=$(mktemp)

# shellcheck disable=SC2064
trap "rm -f '$restart_units' '$stop_units'" EXIT INT TERM HUP

map_path_to_unit() {
	echo "$1" | sed -n '
		s#.*/##g
		s#@\.#*.#
		s#\.container$##p
		s#\.kube$##p
		s#\.pod$#-pod#p
		s#\.network$#-network#p
		s#\.volume$#-volume#p
		s#\.build$#-build#p
		s#\.image$#-image#p
		s#\.artifact$#-artifact#p
	'
}

# update repo
if [ ! -d "$LOCAL/.git" ]; then
	git clone --branch "$REPOBRANCH" "$REPO" "$LOCAL"
	before_rev=$(git -C "$LOCAL" hash-object -t tree /dev/null)
else
	before_rev=$(git -C "$LOCAL" rev-parse HEAD)
	git -C "$LOCAL" pull --ff-only
fi
after_rev=$(git -C "$LOCAL" rev-parse HEAD)

# link to systemd
mkdir -p ~/.config/containers
ln -fsn "$LOCAL/$REPODIR" ~/.config/containers/systemd
systemctl --user daemon-reload

# find changed quadlets
git -C "$LOCAL" diff --name-status --find-renames "$before_rev" "$after_rev" -- "$REPODIR" |
	while IFS="$(printf '\t')" read -r status old_path new_path; do
		[ -n "$status" ] || continue
		old_unit=$(map_path_to_unit "$old_path")
		new_unit=$(map_path_to_unit "$new_path")

		case "$status" in
		D)
			echo "$old_unit" >>"$stop_units"
			;;
		R*)
			echo "$old_unit" >>"$stop_units"
			echo "$new_unit" >>"$restart_units"
			;;
		*)
			echo "$old_unit" >>"$restart_units"
			;;
		esac
	done

# stop units
cat "$stop_units" |
	xargs -r systemctl --user stop || true

# restart units
cat "$restart_units" |
	xargs -r systemctl --user try-restart || true
