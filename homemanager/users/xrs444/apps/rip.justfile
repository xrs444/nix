# Disc ripping for Romm, via redumper — xdt1-t only
# (redumper is installed system-wide in hosts/nixos/xdt1-t/desktop.nix)
#
# redumper auto-detects the inserted media, so the same `rip` recipe below
# covers every platform: CDs (PS1, DOS) dump to .bin/.cue, DVDs (Xbox, PC)
# dump to .iso. What differs is what happens after the rip — see
# "ROMM Game Configs/README.md" for the full per-platform table, summary:
#   dos  — run `setup-config` to generate a DOSBox conf interactively
#   psx  — no extra step; drop the .bin/.cue straight into its game folder
#   win  — no extra step; catalog/download-only in RomM (no browser core)
#   xbox — no extra step, BUT original Xbox (XGD) discs need a Kreon-firmware
#          DVD drive to read the security sectors. A stock drive will not
#          produce a valid dump. Catalog/download-only in RomM either way.
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

# DOS only. Launch DOSBox against a ripped game (mounts games_dir/<name> as
# C: and its .cue as D:) to run the installer interactively — e.g. sound card setup.
# Romm's own dosbox-pure mount is ephemeral, so whatever the installer writes
# (config files) must be generated here, on real disk, then packaged into the
# game's zip alongside the exe/conf/CD folder for Romm to serve permanently.
setup-config name:
	#!/usr/bin/env fish
	set -l dir "{{games_dir}}/{{name}}"
	set -l cue "$dir/{{name}}.cue"
	if not test -f "$cue"
		echo "No cue file at $cue — run 'just rip' first"
		exit 1
	end
	dosbox -c "mount c \"$dir\"" -c "imgmount d \"$cue\" -t iso -fs iso" -c "c:"

# --- Automatic Ripping Machine (ARM) — CD/DVD/Blu-Ray ripping for Jellyfin ---
# On-demand only: ARM is NOT a boot service (nix/modules/services/arm only sets
# up docker + the NVIDIA runtime + secrets on xdt1-t). Start it before ripping,
# stop it when done — arm-start/arm-stop below own the container lifecycle.
# xdt1-t has two optical drives (/dev/sr0, /dev/sr1); ARM rips both in parallel.
# Requires nix/secrets/arm.yaml filled in (MakeMKV key + OMDb API key) and
# deployed, and HB_PRESET_DVD/HB_PRESET_BD in the ARM config set to an NVENC
# preset (see arm-list-presets) — ARM's own defaults are CPU x264 presets.

arm_dir := "/home/xrs444/rips/arm"

# Start ARM: both drives + GPU passed through, on-demand (no --restart).
# --privileged is required for ARM's internal udev to see disc-insert events.
arm-start:
	#!/usr/bin/env fish
	mkdir -p {{arm_dir}}/music {{arm_dir}}/logs {{arm_dir}}/media {{arm_dir}}/config
	docker run -d --rm --name arm \
		-p 8080:8080 \
		-e ARM_UID=(id -u) \
		-e ARM_GID=(id -g) \
		-e TZ=(timedatectl show -p Timezone --value) \
		-e NVIDIA_VISIBLE_DEVICES=all \
		-e NVIDIA_DRIVER_CAPABILITIES=all \
		--gpus all \
		-v "{{arm_dir}}:/home/arm" \
		-v "{{arm_dir}}/music:/home/arm/music" \
		-v "{{arm_dir}}/logs:/home/arm/logs" \
		-v "{{arm_dir}}/media:/home/arm/media" \
		-v "{{arm_dir}}/config:/etc/arm/config" \
		--device="/dev/sr0:/dev/sr0" \
		--device="/dev/sr1:/dev/sr1" \
		--privileged \
		automaticrippingmachine/automatic-ripping-machine:latest
	echo "ARM starting — web UI at http://localhost:8080 (default admin/password — change it)"
	echo "Waiting for config/arm.yaml to be seeded…"
	for i in (seq 1 30)
		if test -f "{{arm_dir}}/config/arm.yaml"
			break
		end
		sleep 1
	end
	just -f "{{justfile()}}" arm-seed-keys

# Inject MakeMKV + OMDb keys from sops secrets into ARM's persisted config.
# Safe to re-run any time, e.g. after the free MakeMKV beta key rotates.
arm-seed-keys:
	#!/usr/bin/env fish
	set -l cfg "{{arm_dir}}/config/arm.yaml"
	if not test -f "$cfg"
		echo "No $cfg yet — run 'just arm-start' first so ARM can seed its default config."
		exit 1
	end
	sed -i "s|^MAKEMKV_PERMA_KEY:.*|MAKEMKV_PERMA_KEY: \"(cat /run/secrets/arm-makemkv-key)\"|" "$cfg"
	sed -i "s|^OMDB_API_KEY:.*|OMDB_API_KEY: \"(cat /run/secrets/arm-omdb-key)\"|" "$cfg"
	echo "Keys seeded into $cfg — restart ARM (arm-stop then arm-start) if it was already running."

# List HandBrake's built-in preset names inside the ARM image, so you can pick
# an NVENC one (e.g. containing "NVEnc") for HB_PRESET_DVD/HB_PRESET_BD in
# config/arm.yaml — ARM's shipped defaults are CPU x264/x265 presets.
arm-list-presets:
	docker run --rm --gpus all automaticrippingmachine/automatic-ripping-machine:latest HandBrakeCLI -z

# Stop the ARM container (it's --rm, so this also removes it).
arm-stop:
	docker stop arm

# Is ARM currently running?
arm-status:
	docker ps --filter name=arm
