# Disc ripping for Romm (bin/cue), via redumper — xdt1-t only
# (redumper is installed system-wide in hosts/nixos/xdt1-t/desktop.nix)
set shell := ["fish", "-c"]

games_dir := "/home/xrs444/rips/games"

default:
	@just --list

# List optical drives redumper can see — use one of these paths as `drive` below
list-drives:
	redumper --list-all-drives

# Rip the disc in `drive` (e.g. /dev/sr0) to games_dir/<name>/<name>.bin + .cue
rip drive name:
	#!/usr/bin/env fish
	set -l out "{{games_dir}}/{{name}}"
	mkdir -p "$out"
	redumper disc --drive="{{drive}}" --image-path="$out" --image-name="{{name}}"
