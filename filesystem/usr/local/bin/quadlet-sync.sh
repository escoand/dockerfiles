#!/bin/sh

set -eu

start_units=$(mktemp)
restart_units=$(mktemp)
stop_units=$(mktemp)

# shellcheck disable=SC2064
trap "rm -f '$start_units' '$restart_units' '$stop_units'" EXIT INT TERM HUP

map_path_to_unit() {
	echo "$1" | sed -n '
		s#.*/##g
		s#@\.#*.#
		s#\.artifact$#-artifact#p
		s#\.build$#-build#p
		s#\.container$##p
		s#\.image$#-image#p
		s#\.kube$##p
		s#\.network$#-network#p
		s#\.pod$#-pod#p
		s#\.volume$#-volume#p
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
		A)
			echo "$old_unit" >>"$start_units"
			;;
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
xargs -rt systemctl --user stop <"$stop_units" || true

# start units
xargs -rt systemctl --user start <"$start_units" || true

# restart units
xargs -rt systemctl --user try-restart <"$restart_units" || true
