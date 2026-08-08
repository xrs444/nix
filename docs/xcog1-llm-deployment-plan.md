# xcog1 (Mac Mini M4 Pro) — LLM Stack Design Review & Deployment Plan

**Date:** 2026-08-06 · **Status:** hardware arrived, config committed but never run on real hardware.

Scope reviewed: `nix/hosts/darwin/xcog1/default.nix`, `nix/modules/packages-darwin/llm-stack/default.nix`,
`nix/hosts/darwin/default.nix` (base), flake wiring, sops layout, flux consumers (hermes-t/s/k),
monitoring stack, and HuggingFace/nixpkgs upstream reality. The original family-agent plan doc
(`purely-theoretical-at-this-vivid-engelbart.md`) has been garbage-collected from `~/.claude/plans/`;
this document supersedes it as the deployment reference.

---

## 1. Verdict

**The architecture is still the right one.** MLX-lm per-model daemons + LiteLLM as the single
OpenAI-compatible front door + Wyoming voice services on launchd system daemons is the correct
shape for an M4 Pro cognition node, and it matches the repo's established nix-darwin/DS-Nix
patterns. No redesign needed.

**But the config as committed will not deploy.** It was written speculatively before the hardware
existed and contains two hard defects (nonexistent model repos, a broken on-demand launchd
mechanism), four unfinished placeholders that would crash-loop on activation, and several security
gaps (unauthenticated LiteLLM exposing the paid cloud tier to the whole LAN being the worst).
All are fixable in Phase 0 before the Mac is even unboxed — and the good news from this review:
**every "is it packageable?" TODO in the module is now resolved** (`mlx-lm`, `litellm` + proxy
extras, `wyoming-faster-whisper`, and `wyoming-piper` all exist in nixpkgs, with aarch64-darwin
support verified).

`nix eval .#darwinConfigurations.xcog1.system.drvPath` passes today — all defects below are
build-time or runtime, which is exactly why they survived review-by-eval until now.

---

## 2. Review findings

### 2.1 Blockers (deployment fails or feature is inert)

**B1 — Both pinned model repos do not exist on HuggingFace.** Verified via the HF API
(anonymous 401 = not found):

| Configured (wrong) | Actual repo | Pin to revision |
|---|---|---|
| `mlx-community/Qwen3-14B-Instruct-4bit` | `mlx-community/Qwen3-14B-4bit` | `a4d9b2df59d2c150bef02fcbe0d91046b7ca33a4` |
| `mlx-community/Qwen3-30B-A3B-Instruct-4bit-DWQ` | `mlx-community/Qwen3-30B-A3B-Instruct-2507-4bit-DWQ` | `53bfb233acb2e50f6060c3c5709f23fac547827f` |

Qwen3 dense models never had an "-Instruct" suffix (they are hybrid thinking models); the 30B
MoE instruct variant is the 2507 release. Fixing this also resolves the `revision = "main"`
supply-chain TODO — pin the SHAs above.

**B2 — `mlxLmPackage` and `litellmPackage` are empty Python environments.** The `ps.mlx-lm` /
`ps.litellm` lines are commented out, so the launchd commands reference binaries that don't
exist. Now verified available in nixpkgs (registry: mlx-lm 0.31.3, litellm 1.89.0; confirm attrs
against the flake's pinned `nixos-26.05` at build time):

```nix
mlxLmPackage = pkgs.python3.withPackages (ps: [ ps.mlx-lm ]);
litellmPackage = pkgs.python3.withPackages (ps:
  [ ps.litellm ] ++ ps.litellm.optional-dependencies.proxy);
```

The `proxy` extra is required — without it `litellm --config` (the proxy server) won't start
(needs fastapi/uvicorn/apscheduler etc.; extras list verified present in nixpkgs).

**B3 — Voice daemons are `pkgs.hello` placeholders with `KeepAlive = true`.** On activation all
three would crash-loop forever (launchd respawn + no such binary). Additionally,
`wyoming-kokoro` and `resemblyzer-wyoming` binaries don't exist in nixpkgs *or* upstream in that
form. Resolution in Phase 0: wire `pkgs.wyoming-faster-whisper` (3.5.0, aarch64-darwin
confirmed in its `meta.platforms`) for STT, substitute **wyoming-piper** (nixpkgs 2.3.1) for
TTS day-1, and drop Kokoro/Resemblyzer to Phase D (see D5/D7).

**B4 — The on-demand model mechanism cannot work.** `RunAtLoad = false` +
`KeepAlive.SuccessfulExit = false` means launchd *never starts the job at all* — that
combination only governs respawn after the process has run once. "Starts when a request lands"
requires launchd socket activation (`Sockets` key + a server that accepts a launchd-passed fd),
which `mlx_lm.server` does not support; and the module's comment about `--idle-timeout` refers
to a flag that isn't passed (and isn't a supported `mlx_lm.server` option). LiteLLM would route
`qwen3-30b-a3b` requests to a port with no listener, forever.

*Fix:* make residency a RAM decision, not a launchd trick (see D9). On 48/64 GB, run both
models `alwaysOn` — Qwen3-14B-4bit (~8 GB) + 30B-A3B-4bit (~17 GB) coexist comfortably and MoE
A3B is *faster* than the dense 14B per token. On 24 GB, serve only the 30B-A3B (it is both the
better model and lighter on compute) and drop the 14B entirely. Either way, delete the
`alwaysOn = false` code path or repurpose it honestly (`RunAtLoad = true`, document that
"on-demand" is not supported).

**B5 — `DEEPSEEK_API_KEY` is never delivered.** The LiteLLM config references
`os.environ/DEEPSEEK_API_KEY` but the launchd `EnvironmentVariables` TODO was never resolved —
the cloud tier would 401 on every call. launchd can't read a file into an env var, so use the
standard wrapper pattern:

```nix
command = "${pkgs.writeShellScript "litellm-wrapped" ''
  export DEEPSEEK_API_KEY="$(cat /run/secrets/deepseek-api-key)"
  export LITELLM_MASTER_KEY="$(cat /run/secrets/litellm-master-key)"
  exec ${cfg.litellmPackage}/bin/litellm --config ${litellmConfigFile} \
    --port ${toString cfg.litellmPort} --host 0.0.0.0
''}";
```

with two `sops.secrets` entries in the xcog1 host config. Darwin hosts decrypt with the shared
`user_xrs444` age key (established pattern in `hosts/darwin/default.nix`) — **no `.sops.yaml`
change needed**, just add the keys to a secrets file already covered by `creation_rules` (or a
new `secrets/llm.yaml`, which the existing regex covers). The DeepSeek key already exists in the
cluster (sealed into `hermes-*-config`); reuse the same household key.

**B6 — Placeholder sha256 hashes** — mooted by D1: models leave the Nix store, the `sha256`
option is deleted, and pinning is by HF revision alone. No hash-bootstrap step exists anymore.

### 2.2 Security findings

**S1 — LiteLLM is wide open on `0.0.0.0:4000` with no auth. Highest-impact issue.** Anyone on
any LAN segment that can reach xcog1 gets free use of the local models *and the paid DeepSeek
tier* (cost + data exfil path), including kids' devices and any compromised IoT box that can
route there. Fix (both layers):
- Set `general_settings.master_key = "os.environ/LITELLM_MASTER_KEY"` (sops-delivered, see B5).
  Consumers (hermes-t/s/k, HA, Grafana LLM app) authenticate with `Authorization: Bearer`.
  Without a DB (`store_model_in_db = false`) there are no per-consumer virtual keys — a single
  shared master key is the pragmatic home tier; revisit with a Postgres-backed LiteLLM only if
  per-kid quotas are ever wanted.
- Firewalla rule: allow TCP 4000 to xcog1 only from the k8s node/pod egress and HA; deny from
  kid/IoT VLANs. (Host-local pf is possible on macOS but fights with Apple's ALF tooling;
  network-layer enforcement at the Firewalla matches how the rest of the fleet is segmented.)

**S2 — Wyoming ports (10300/10200/10400) bind 0.0.0.0 with no auth.** The Wyoming protocol has
no authentication at all — anyone who can reach the port can stream audio in/out. Restrict at
the Firewalla to the HA host (`hass.xrs444.net`) as the sole client.

**S3 — Every daemon runs as root.** mlx-lm, LiteLLM, and the voice services parse untrusted
network input with Python/C++ stacks; root is an unnecessary blast radius. Add a dedicated
service user via nix-darwin (`users.knownUsers`/`users.users._llm` with a fixed uid) and set
`UserName = "_llm"` in each daemon's `serviceConfig`, with `/var/log/llm-stack` chowned to it.
(Phase B hardening — do after first successful root bring-up to keep variables down, but before
opening firewall rules to consumers.)

**S4 — Unpinned `revision = "main"`** — resolved by B1's SHAs. Keep the module's "don't ship
main" doctrine. With models out of the store (D1) the pin is the immutable HF commit SHA — the
wrapper only ever downloads that exact revision, so a moved branch ref changes nothing.

**S5 — No log rotation.** `StandardOutPath`/`StandardErrorPath` files grow without bound
(LiteLLM with `json_logs` is chatty). Add an `environment.etc."newsyslog.d/llm-stack.conf"`
entry rotating `/var/log/llm-stack/*` at ~10 MB × 5 archives.

**S6 — Headless-Mac operational hardening (new, was never in the module):**
- `pmset -a sleep 0 disksleep 0 autorestart 1 womp 1` via activation script — without
  `autorestart` the stack stays down after any power blip until someone presses the button.
- **FileVault must stay off** (default) — an encrypted boot volume blocks unattended reboot.
  Accept the tradeoff (no secrets at rest beyond the age key + sops outputs) or accept manual
  unlock after every power event; recommend off for a LAN-only server, consistent with its role.
- Remote Login (SSH) + Screen Sharing: enable in Phase A setup, restrict SSH to the `xrs444`
  user. `softwareupdate --schedule on` for security updates; macOS *major* upgrades stay manual.
- Do not enable auto-login; system daemons need no logged-in user (that's why they're
  `launchd.daemons`, correctly).

**S7 — Secrets model** — the shared `user_xrs444` age key on a second always-on host mildly
widens that key's exposure (already accepted for xlt1-t; xcog1 is headless and physically
secure). Acceptable; noted for the record. If it ever bothers you, mint a dedicated
`host_xcog1` age key and add it to `.sops.yaml` recipients + rekey.

### 2.3 Design / optimization findings

**D1 — Models move OUT of the Nix store; `modelsDir` becomes real. (Decision 2026-08-06.)**
The committed design fetches models as `fetchgit` derivations, which drags ~25 GB through every
build path: remote builders, the CI post-build hook (`nix-post-build-hook.sh` signs and pushes
*every* derivation to nixcache.xrs444.net), and any machine that evaluates/substitutes the
xcog1 closure. The models are only ever needed on xcog1 itself, so:

- **Delete `mkMlxModel`/`fetchgit` and the per-model `sha256` option entirely.** Pinning moves
  to the HF git revision alone (a commit SHA is content-addressing; `hf download` verifies
  file checksums against repo metadata — weaker than a nix hash, acceptable for this trust
  model). Side benefit: the fake-hash bootstrap dance (old B6) disappears.
- **Each mlx daemon's command becomes a self-healing wrapper** — no launchd ordering games,
  no separate downloader unit to sequence:

  ```nix
  command = pkgs.writeShellScript "mlx-lm-${name}" ''
    set -euo pipefail
    dir="${cfg.modelsDir}/${name}"
    if [ ! -f "$dir/.revision" ] || [ "$(cat "$dir/.revision")" != "${revision}" ]; then
      rm -rf "$dir"   # never mix files from two revisions
      export HF_HOME="${cfg.modelsDir}/.hf-cache"
      ${hfCli}/bin/huggingface-cli download ${repo} --revision ${revision} --local-dir "$dir"
      echo "${revision}" > "$dir/.revision"
    fi
    exec ${cfg.mlxLmPackage}/bin/mlx_lm.server --model "$dir" --host 127.0.0.1 --port ${port}
  '';
  ```

  (`hfCli` = `python3.withPackages (ps: [ ps.huggingface-hub ])`; set `HF_HOME` under
  `modelsDir` so root's `~/.cache` stays clean.) `KeepAlive` respawn makes a failed/interrupted
  download self-retry; the `.revision` marker makes restarts a no-op and revision bumps an
  automatic re-download.
- First daemon start on xcog1 downloads ~25 GB — expect the models to take tens of minutes to
  become ready on first boot (watch `/var/log/llm-stack/mlx-lm-*.stderr`); every later start is
  instant.
- **`modelsDir` points at the external SSD from day one** (`/Volumes/xcog1-models`, per the
  original plan — the drive shipped with the Mac). A `modelsVolume` option makes every daemon
  that touches modelsDir **wait for the mount** before writing: writing to an unmounted
  `/Volumes/<name>` path silently creates a plain directory on the boot disk and then blocks
  the real volume from mounting — the classic macOS external-drive trap. The activation script
  correspondingly never creates modelsDir itself. Whisper/Piper caches live there too.

**D2 — `routing_strategy = "usage-based-routing-v2"` requires Redis** and only matters with
multiple deployments of the same model name. With one instance per model it adds a dependency
for zero benefit — delete `router_settings` entirely (default simple-shuffle is correct here).

**D3 — LiteLLM's Prometheus `/metrics` callback is enterprise-gated** in current releases —
don't build §6 alerting on it. Plan: node_exporter (system health) + Prometheus blackbox/probe
against `http://xcog1.lan:4000/health/liveliness` and a scripted probe of each model's
`/v1/models`, mirroring the existing `probe-samba-dc.yaml` pattern in
`flux/apps/observability/monitoring/`.

**D4 — `apple_silicon_exporter` doesn't exist in nixpkgs** and the daemon block is already
commented out. Defer to Phase D (candidates: `macmon`-based textfile collector). node_exporter
covers CPU/mem/disk/net day-1; GPU/ANE metrics are nice-to-have.

**D5 — Speaker ID (Resemblyzer) can't plug into HA Assist as designed.** The Wyoming protocol
has no speaker-identification event type — HA would never call it. This needs a custom HA
component or a wrapper around the STT stream. Move to Phase D as an experiment; do not block
the voice rollout on it. (Delete the placeholder daemon now — see B3.)

**D6 — Whisper via faster-whisper is CPU-only on macOS** (CTranslate2 has no Metal backend).
On an M4 Pro, `large-v3` will be noticeably laggy for voice; **default the module to
`large-v3-turbo`** (≈6–8× faster, near-identical accuracy for command STT) and revisit an
`mlx-whisper` Wyoming bridge later if latency still annoys.

**D7 — Kokoro TTS is unpackaged** (needs a custom derivation; upstream has no Wyoming wrapper).
Ship **wyoming-piper from nixpkgs** in Phase C for a working end-to-end voice loop; add Kokoro
in Phase D as a quality upgrade behind the same option interface.

**D8 — Qwen3-14B is a hybrid *thinking* model.** For the voice path, thinking mode means
seconds of hidden reasoning tokens before the first spoken word. If the 14B is kept (64 GB RAM
case), HA's conversation agent prompt must include `/no_think` (or the request must set
`chat_template_kwargs: {"enable_thinking": false}`). The 30B-A3B-Instruct-2507 is non-thinking
— another reason it's the better primary (see D9).

**D9 — Residency is a RAM decision — check on first boot:** `sysctl -n hw.memsize`.

| RAM | Plan |
|---|---|
| 64 GB | Both models `alwaysOn` (8 + 17 GB) + whisper-turbo + piper. Headroom for Kokoro later. |
| 48 GB | Same as 64 GB; fine. Skip any third model. |
| 24 GB | **Serve only `qwen3-30b-a3b`** (wired-memory pressure with both + STT is too tight). It also serves the voice path — A3B's 3 B active params give better tokens/sec than the dense 14B. |

**D10 — hermes Phase B swap (flux repo).** All three hermes instances currently call DeepSeek
directly (`provider: deepseek`, per-namespace sealed `DEEPSEEK_API_KEY`; the hermes-k secret
comment already anticipates this swap). Once LiteLLM is verified: point each hermes at
`http://xcog1.lan:4000/v1` with the LiteLLM master key sealed into each namespace, set default
model `qwen3-30b-a3b` (hermes-t/s may keep `deepseek-hard` as an escalation tier), then remove
the raw DeepSeek keys from hermes-t/s/k so the only holder of the upstream key is xcog1. Kid
policy note: hermes-k should *not* get the `deepseek-hard` model name in its config.

**D11 — Monitoring wiring is entirely missing on the flux side.** Add xcog1 to the
`prometheus-additional-scrape-configs` sealed secret (node_exporter `xcog1.lan:9100`) and add
the D3 probes + basic alert rules (host down, LiteLLM liveliness failing, disk >85%). Follow
`nix/docs/monitoring.md` / `alerting-guide.md` conventions. Add a Dashy entry if desired.

**D12 — Minor:** `.claude/CLAUDE.md` `@.infrastructure-reference.md` include points at a path
that doesn't exist (file lives at repo root, one level up) — fix the reference or symlink;
today's sessions load nothing from it.

### 2.4 What's right — keep as-is

- **MLX over Ollama/llama.cpp**: measurably faster on Apple Silicon, first-class 4-bit/DWQ
  quants from mlx-community, and per-model daemons give clean launchd lifecycle. Right call.
- **LiteLLM as the single front door** with named model routing + cloud tier: exactly the
  standard pattern; every consumer speaks OpenAI-compatible to one host:port.
- **System daemons, not user agents** — survives logout/reboot, correct for a headless node.
- **mlx servers bound to 127.0.0.1**, only LiteLLM exposed — correct layering.
- **Remote-builder + DS Nix + nix.custom.conf setup** — matches xlt1-t exactly (and the
  `nix.buildMachines`-with-`nix.enable=false` combo is proven live on xlt1-t).
- **Host in flake as `darwinConfigurations.xcog1`** with the standard host attrset — evaluates
  clean today.

---

## 3. Deployment plan

Deployment mechanism reality (per repo convention): Darwin hosts are **not** in `deploy.nodes`;
every activation is a local `darwin-rebuild switch --flake .#xcog1` run by you (needs
interactive sudo/Touch ID). CI/commit-push only updates the source of truth. Everything below
is automated *in nix* where possible; the listed manual steps are the ones macOS physically
won't let us script.

### Phase 0 — Fix the module (on xlt1-t, before unboxing) — ~1 session

All verifiable by eval/build locally since this Mac is also aarch64-darwin.

1. **B1/D1**: correct both model repos, pin revisions (SHAs in §2.1), and replace the
   `fetchgit`/`sha256` machinery with the out-of-store downloader wrapper (mechanism in D1).
2. **B2**: wire real `mlx-lm` / `litellm`(+proxy extras) packages; confirm attrs exist in the
   pinned `nixos-26.05`.
3. **B4**: remove the broken on-demand path — both models `alwaysOn = true` (final residency
   decided at Phase B per D9).
4. **B3/D5/D7**: replace whisper placeholder with `pkgs.wyoming-faster-whisper`
   (model `large-v3-turbo`), replace kokoro option with piper (`pkgs.wyoming-piper`, port
   10200), **delete** the resemblyzer daemon + option.
5. **B5/S1**: sops secrets (`deepseek-api-key`, `litellm-master-key`) + shell-wrapper command
   for LiteLLM; add `general_settings.master_key`; drop `router_settings` (D2).
6. **S5/S6**: newsyslog rotation config + `pmset` activation script.
7. Build gate: `nix build .#darwinConfigurations.xcog1.system` — should complete cleanly
   (no model data is fetched at build time anymore; the closure stays small enough for the
   remote builders and cache push). Commit.

### Phase A — Hardware bring-up — ~1 evening

Manual (macOS setup assistant): create user `xrs444`, hostname `xcog1`, skip Apple
Intelligence/iCloud extras, enable Remote Login + Screen Sharing, plug into the servers VLAN.

1. Firewalla/DHCP: static reservation + DNS `xcog1.lan`; confirm `ssh xrs444@xcog1.lan`.
   Prepare the external SSD: `diskutil eraseDisk APFS xcog1-models <disk>` then
   `sudo diskutil enableOwnership /Volumes/xcog1-models` (external volumes default to
   "ignore ownership", which would break root-owned model dirs).
2. Install Determinate Systems Nix, then Homebrew (required by `brew-packages.nix`;
   remember `onActivation.cleanup = "none"` is already the repo norm).
3. Copy the age key to `~/.config/sops/age/keys.txt` (same key as xlt1-t).
4. Copy `~/.ssh/builder_key` (remote-builder credential) from xlt1-t.
5. `git clone` the nix repo; `darwin-rebuild switch --flake .#xcog1` (first run: expect
   LuLu-style firewall prompts; cerebrum notes apply). **The first switch builds the
   aarch64-darwin closure on xcog1 itself** (decision 2026-08-07: no pre-building from
   xlt1-t; CI runners are Linux and can't cover darwin builds) — it substitutes what
   cache.nixos.org/nixcache have and compiles the rest (Qt, ffmpeg, etc.); budget an hour
   or two and run it under `caffeinate -im`. Model downloads (~25 GB) then happen on first
   daemon start; watch `/var/log/llm-stack/mlx-lm-*.stderr` until both models are serving.
6. Record RAM (`sysctl -n hw.memsize`) → apply D9 decision, adjust models if 24 GB, commit.
7. Verify base: fish shell, nix.custom.conf substituters, node_exporter answering on :9100,
   Tailscale app if the `tailscale-client` role is wanted day-1.

### Phase B — LLM stack live + consumers — ~1 session

1. Verify daemons: `sudo launchctl list | grep net.xrs444`, tail `/var/log/llm-stack/*`.
2. Smoke test locally on xcog1, then from xlt1-t:
   `curl http://xcog1.lan:4000/v1/models -H "Authorization: Bearer $MASTER_KEY"`, then a chat
   completion against `qwen3-30b-a3b` and `deepseek-hard`.
3. **S3 hardening**: add `_llm` user + `UserName` on all daemons; re-switch; re-verify.
4. Firewalla rules (S1/S2): 4000 ← k8s egress + HA only; 10300/10200 ← HA only; 9100 ←
   Prometheus egress only. Verify a kid-VLAN device gets connection-refused/timeout.
5. **hermes swap (D10)** in the flux repo: base URL + sealed master key per namespace; deploy
   hermes-s first (lowest blast radius), then hermes-t, then hermes-k; remove per-namespace
   DeepSeek keys.
6. **Monitoring (D11)**: re-seal `prometheus-additional-scrape-configs` with xcog1 targets;
   add probes + alert rules; confirm targets Up in Prometheus.

### Phase C — Voice pipeline — ~1 session

1. Whisper + Piper daemons verified via `nc`/Wyoming handshake from the HA host.
2. HA: add Wyoming integrations (`xcog1.lan:10300` STT, `:10200` TTS), create an Assist
   pipeline with conversation agent = OpenAI-compatible → `http://xcog1.lan:4000/v1`,
   model per D9 (with `/no_think` if the 14B serves voice, per D8).
3. Latency budget check end-to-end (target: wake→response start < 3 s). If STT is the long
   pole, drop whisper model size before touching anything else.

### Phase D — Enhancements (unscheduled, independent)

- Kokoro TTS derivation behind the existing TTS option (D7).
- Speaker-ID experiment with a custom HA component (D5).
- Apple-silicon GPU/ANE metrics exporter (D4).
- Grafana dashboard for token throughput once a metrics source exists (D3 constraint).
- Restic backup job **only if** stateful data appears (today: nothing on xcog1 is
  unreproducible — config is git, models are pinned fetches, secrets are in sops).

---

## 4. Verification checklist (exit criteria)

- [ ] `nix build .#darwinConfigurations.xcog1.system` clean on committed main; closure contains
      no model weights (models live in `modelsDir`, pinned by revision marker).
- [ ] All launchd daemons running as `_llm`, surviving reboot **and** power-pull test (autorestart).
- [ ] LiteLLM rejects unauthenticated requests; accepts master key; both local models + cloud tier answer.
- [ ] Port 4000/10300/10200 unreachable from kid/IoT VLANs; reachable from HA/k8s.
- [ ] hermes-t/s/k all chatting via LiteLLM; no `DEEPSEEK_API_KEY` left in hermes namespaces.
- [ ] Prometheus: xcog1 node target Up; liveliness probe green; host-down alert fires when unplugged.
- [ ] HA voice pipeline round-trip < 3 s; TTS audible; works with xcog1 as sole STT/TTS provider.
- [ ] Logs rotating (`ls -la /var/log/llm-stack` after a week < 100 MB).
