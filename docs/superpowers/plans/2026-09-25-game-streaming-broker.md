# Game Streaming + Core Broker Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Stream games from the desktop with Sunshine → Moonlight, and let `core` (the homelab box, separate repo `~/homelab`) wake the desktop and *request* a broker-owned Steam session when nobody is using it — without Core ever proxying video or directly controlling the desktop's sessions.

**Architecture:** The video path is always Desktop/Sunshine ↔ Moonlight client. Core only does Wake-on-LAN, polls status, and asks for start/stop through a restricted forced-command SSH dispatcher on the desktop. The desktop decides: a root supervisor (`game-broker@<request_id>.service`) runs a staged state machine that stops SDDM, starts a real PAM/logind session (`game-broker-session@<request_id>.service`, `User=withrin` + `PAMName=` + `TTYPath=`) running gamescope → Steam Gamepad UI → Sunshine on a dummy HDMI plug, and restores SDDM on any exit.

**Status (2026-09-25):** Plan approved. Stage 0 partly recorded. Stage 1 switched and running on the desktop (uncommitted) with **Vulkan Video encoding, not NVENC** — see Stage 1 results. First Moonlight test (phone) streams. Remaining Stage 1 validations are pending before commit. Stage 4 must NOT be implemented yet.

## Global Constraints

- **Core asks. The desktop decides.** Core never runs `systemctl`, `loginctl`, `pkill` or a shell on the desktop. Its key is pinned to a dispatcher with fixed verbs.
- **Never two graphical `withrin` sessions at once.**
- **Normal local sessions are untouched.** With COSMIC/Plasma logged in, Sunshine runs as the ordinary user service and Core is uninvolved: no logout, no VT switch, no layout/resolution change, no suspend. No Sunshine `prep-cmd`, ever.
- **`unknown` and `inconsistent` ownership fail closed** — every mutating verb refuses.
- **Smallest reliable design.** No HTTP, database, dashboard, virtual display, headless gamescope or automatic suspend until a stage demonstrates the need.
- **nix-config pins `nixos-unstable` @ `8ce4ef6`; homelab pins `nixos-26.05` @ `d57af92`.** Verify module claims against the store copy matching each `flake.lock`, not the registry.
- **Concrete first:** host-specific files, no new `myConfig.*` options.
- Commit style: small, scoped, 1–2 line subject.

## Verified facts (pinned sources / live system)

| Item | Finding |
|---|---|
| Desktop hardware | RTX 2070 Super, open kernel module, driver 595.99.02; MSI MAG B550 TOMAHAWK MAX WIFI; NIC `enp42s0` (r8169), MAC `d8:43:ae:70:e6:a8`; `mem_sleep` = `deep` |
| Versions | systemd 261.2, gamescope 3.16.28, Sunshine `2026.516.143833`, kernel 7.2.4 |
| Addresses | LAN 192.168.0.205 (reservation not yet confirmed); tailnet **100.71.146.43**; core 192.168.0.125 / 100.109.198.88 |
| Connectors | DP-1, DP-2, HDMI-A-1 in use; **HDMI-A-2 free** (currently `disconnected`) → dummy plug goes there |
| Sunshine `openFirewall` | Writes the **global** port lists. Ports: TCP 47984, 47989, 47990 (web UI), 48010; UDP 47998, 47999, 48000, 48002, 48010 |
| Sunshine web UI | `origin_web_ui_allowed` default `lan`, and Sunshine classifies 100.64.0.0/10 as LAN → use `pc` |
| UPnP | Default `disabled`; set explicitly anyway |
| `capSysAdmin` | Needed: KMS is the only unattended capture on NVIDIA Wayland (portal is interactive, NvFBC is X11 + CUDA-only) |
| NVENC | **The planning-time claim was wrong.** nixpkgs builds with `cudaSupport = config.cudaSupport` (false) → `SUNSHINE_ENABLE_CUDA=OFF`. Reading the source suggested NVENC would still work via a GPU → RAM → GPU copy. On the hardware it does not: `libcuda.so.1` lives in `/run/opengl-driver/lib`, which is not in the binary's RUNPATH (nixpkgs adds a library path only in the CUDA build), and the capability wrapper makes the process secure-exec, so glibc ignores `LD_LIBRARY_PATH`. Journal: `Cannot load libcuda.so.1` → `Encoder [nvenc] failed` → `Found H.264 encoder: h264_vulkan [vulkan]`, `Found HEVC encoder: hevc_vulkan [vulkan]`. AV1 is unavailable (Turing cannot encode it). Vulkan Video is still GPU hardware encoding |
| Sunshine udev | The nixpkgs package ships **no** udev rules. `/dev/uinput` already has a withrin ACL (Xbox-style virtual pads work); `/dev/uhid` is root `0600`, so DS5 emulation logs `Gamepad ds5 is disabled due to Permission denied` |
| Sunshine KMS monitor ids | Monitor 0 = HDMI-A-1, 1 = DP-1, 2 = DP-2 (dummy on HDMI-A-2 not yet connected) |
| Sunshine autostart | User unit `wantedBy graphical-session.target`; `cosmic-session.target` `BindsTo=graphical-session.target` (verified active) |
| COSMIC in logind | `Service=sddm Class=user Type=wayland VTNr=3`; `loginctl list-sessions --json=short` works |
| `PAMName=` | Main process migrates into `session-N.scope`; **children belong to the scope only** (`systemd.exec(5)`) — the service's KillMode does not contain Steam |
| logind | `KillUserProcesses = false` (NixOS default) → closed sessions can linger with processes |
| `pam_systemd` | Accepts `class=` / `type=`; NixOS rule defaults to `control = "optional"` |
| `display-manager.service` | `restartIfChanged = false` |
| `Conflicts=` | "starting it will stop all of them" — would let the session unit stop SDDM on its own |
| WOL | `networking.interfaces.<n>.wakeOnLan` emits a udev `.link` file (works under NetworkManager). Currently `device/power/wakeup` = `disabled`. NM connection `Wired connection 1` is auto-generated, `wake-on-lan=default` |
| sops trap | `modules/core/sops.nix` sets `age.keyFile` only when sshd is **off**; enabling sshd switches to an unenrolled host key → `withrin_password` fails → lockout |
| Core subnet route | Core advertises 192.168.0.0/24 and SNATs, so tailnet traffic via that route arrives on `enp42s0` as 192.168.0.125 |
| Core tools | `wakeonlan` in 26.05; util-linux 2.42.2 has `uuidgen --time-v7` |

## Decisions

- ~~Non-CUDA Sunshine/NVENC RAM-copy path accepted for MVP~~ — superseded: that path does not exist in practice (see Verified facts, NVENC).
- **Stage 1 uses the stock Sunshine package with Vulkan Video encoding** (`h264_vulkan` / `hevc_vulkan`). Stage 1's job is to establish whether Vulkan is adequate on this hardware before any package customization.
- **First follow-up experiment, only if Moonlight testing shows unacceptable encode latency, GPU utilization, frame pacing or quality:** set `services.sunshine.package` to a `runCommand` that copies the stock binary and runs `patchelf --add-rpath /run/opengl-driver/lib` (no recompile; RUNPATH is still honoured under secure-exec). That makes `libcuda.so.1` loadable, so NVENC runs with the GPU → RAM → GPU copy; compare it against Vulkan. A full `cudaSupport = true` build (zero-copy, uncached, compiled locally on every bump) comes after that, if ever.
- **DS5 controller emulation is deferred.** Xbox-style virtual pads are sufficient for the baseline. If testing shows a need, add `services.udev.extraRules = ''KERNEL=="uhid", TAG+="uaccess"'';` as its own commit.
- Laptop's `withrin` key may SSH to the desktop as an ordinary shell (password sudo) — the Core-independent recovery path. It gets **no** broker NOPASSWD rule.
- Core's broker key is the only restricted forced-command identity.
- Core v1 is a CLI that re-derives state from desktop status on every call; no daemon until Stage 5.
- `capSysNice` for gamescope stays off; `programs.steam.gamescopeSession` stays off.

## Design

### Ownership (derived locally for every verb; never taken from Core)

- `none` — no broker state file, no `Service=game-broker` session, no local graphical session, no lingering withrin `steam`/`sunshine`.
- `local` — ≥1 session with `Class=user`, `Type ∈ {x11,wayland}`, `Service ≠ game-broker`, **any state including `closing`**, and no broker evidence.
- `broker` — all agree: state file exists, `boot_id` = current, supervisor active with matching `InvocationID`, logind session/scope expected at the current stage exists.
- `inconsistent` — any mix or any missing piece.
- `unknown` — any logind/systemd query failed.

Runtime state: `/run/game-broker/state.json` (supervisor `RuntimeDirectory=`, written atomically):

```json
{"owner":"broker","request_id":"019…","session_id":"…","boot_id":"…",
 "unit_invocation_id":"…","logind_session_id":"…","stage":"ready","preset":"switch"}
```

### Protocol v1 (forced-command SSH, JSON on stdout only)

```
status
start <request_id> <preset> <expected_boot_id>
stop <session_id> <boot_id>
```

Every response carries `agent_version`, `protocol: {major: 1, minor: 0}`, `capabilities`. Core rejects a different major. Unsupported facts are reported as `null` with a `source: "unsupported"` marker, never guessed.

Rejection reasons: `unknown_verb`, `invalid_argument`, `local_graphical_session_active`, `greeter_not_present`, `lingering_user_processes`, `sunshine_already_running`, `broker_busy`, `ownership_inconsistent`, `ownership_unknown`, `boot_mismatch`, `request_expired`, `request_already_consumed`, `session_mismatch`, `not_broker_owned`, `stage_timeout:<stage>`.

### Idempotency / replay

- **Starts are boot-bound.** Core reads `boot_id` from `status` after wake and sends it as `expected_boot_id`; mismatch → `boot_mismatch`. This covers replay across reboots, so **no persistent seen-set**.
- Within a boot: `/run/game-broker-requests/<request_id>.json` records each request and its outcome (tmpfs, cleared exactly when `boot_id` changes). Same `request_id` → same answer; a consumed id never starts a second session.
- Remaining gap: suspend/resume keeps `boot_id`. Keep the optional UUIDv7 window (reject > ~120 s old or > ~30 s in the future) as defense in depth against a very late first delivery.
- Supervisor instance name = `request_id`, so a duplicate start is a systemd no-op. All mutations hold `flock /run/lock/game-broker.lock`.
- `stop` must match both `session_id` and `boot_id` from `state.json`; a stale stop cannot touch a newer session.
- Mutations use `systemctl start --no-block` + polling, so a dropped SSH connection never kills the operation; the retry returns existing state.

### Units

**Supervisor** — `game-broker@<request_id>.service` (root)
- `Type=notify`, `RuntimeDirectory=game-broker`, `restartIfChanged=false`.
- Sends `READY=1` **before** `creating-session` (required by the session unit's `Requisite=`).
- `ExecStopPost=` runs the teardown stages unconditionally (runs after crash/SIGKILL too). Teardown must work without `state.json` (fall back to finding `Service=game-broker` sessions).
- Only component allowed to do check → stop SDDM → re-check.

**Session** — `game-broker-session@<request_id>.service` (no `Conflicts=`, no `RefuseManualStart=`)

```
Requisite=game-broker@%i.service
After=game-broker@%i.service
BindsTo=game-broker@%i.service
ExecCondition=+<verify-authorization>
User=withrin  PAMName=game-broker
TTYPath=/dev/tty8  StandardInput=tty-fail  TTYReset=yes TTYVHangup=yes TTYVTDisallocate=yes
UtmpIdentifier=tty8  UtmpMode=user
Environment=XDG_SESSION_TYPE=wayland XDG_SESSION_CLASS=user XDG_SEAT=seat0 XDG_VTNR=8
ExecStartPre=+chvt 8
Restart=no  restartIfChanged=false
```

`verify-authorization` (root, runs before anything else) requires: `state.json` `stage == "creating-session"` and `request_id == %i`; its `unit_invocation_id` equals the live supervisor `InvocationID`; `boot_id` current; `display-manager` inactive; no greeter or `Class=user` graphical session; no other `game-broker-session@*` active. Any failure → unit skipped, no side effects. `RefuseManualStart=` was rejected: the supervisor's own `systemctl start` counts as manual, so it would only move the entry point to a dummy target.

```nix
security.pam.services.game-broker = {
  startSession = true;
  rules.session.systemd = { control = "required"; settings = { class = "user"; type = "wayland"; }; };
};
```

**Session launcher** (withrin, inside `session-N.scope`): `gamescope --backend drm -O HDMI-A-2 -W 1280 -H 720 -w 1280 -h 720 -r 60 -e -- steam -gamepadui`, then — once the connector is lit — `/run/wrappers/bin/sunshine <broker.conf>` as a child in the same scope (shares `~/.config/sunshine`, so pairings carry over). Exits when gamescope exits.

### Stages

| Stage | Timeout | Success condition | Compensation |
|---|---|---|---|
| validating | 5 s | ownership `none`, greeter present, DM active, port 47989 free, no lingering withrin steam/sunshine | none needed |
| stopping-greeter | 15 s | DM inactive **and** re-check finds no greeter/user session | if a user session appeared: abort, `inconsistent`, do not start |
| creating-session | 15 s | session `Active=yes Service=game-broker Type=wayland VTNr=8` | teardown |
| starting-display (+steam) | 30 s | gamescope and steam in scope; HDMI-A-2 `enabled` | teardown |
| starting-sunshine | 30 s | 47989 listening; journal shows `Found H.264 encoder` (currently `h264_vulkan`) | teardown |
| ready | — | steam reported `running` (process), UI readiness `unsupported` | — |
| stopping-steam | ~30 s grace | `steam -shutdown` via `runuser -u withrin` (session's `XDG_RUNTIME_DIR`/`HOME`; **not** `systemd-run --user`); no steam left in scope | moves on either way |
| terminating-session | 15 s | `loginctl terminate-session N`; scope gone | next stage |
| killing-scope | 5 s | `systemctl kill -s KILL session-N.scope` — fallback only, logged `degraded_teardown` | — |
| restoring-greeter | 30 s | DM active, greeter session present | leave on TTY, report degraded; local recovery |
| failed | terminal | reason recorded in `/run/game-broker-requests/` | — |

### Known failure modes to test for

- Physical login between greeter check and SDDM stop (TOCTOU) — narrowed by re-check, accepted residual.
- VT not foreground → session not Active → no DRM master / uinput uaccess.
- `nixos-rebuild switch` during a broker session.
- Lingering COSMIC session with Steam still running would absorb `steam -gamepadui` via single-instance IPC.
- Dispatcher's own SSH login appears in logind (class `background`, `Remote=yes`) and starts `user@` for `broker-control`; exclude via `$XDG_SESSION_ID`; consider `linger` if polls are slow.
- Steam first-run update/login inside gamescope.
- WOL after AC loss; IP change after cold boot; tailscaled late after resume (Core tries LAN first).
- Unknown whether gamescope's DRM backend passes Ctrl+Alt+F*n* VT switching → laptop SSH is the recovery path.

### Files

**nix-config**
- Create `modules/services/sunshine.nix` (Stage 1).
- Modify `hosts/desktop/default.nix`: import, per-interface Sunshine ports (Stage 1); `wakeOnLan` (Stage 2); sshd port 22 per interface + sops pin (Stage 3); import `./game-broker.nix`.
- Create `hosts/desktop/game-broker.nix` (Stage 3/4): sshd, `broker-control` user, forced command, sudo rule (Stage 4 only), PAM service, units, broker `sunshine.conf`.
- Create `hosts/desktop/game-broker/{lib,remote,ctl,supervisor,session}.sh` — separate files so `writeShellApplication` shellchecks them; `lib.sh` holds the one ownership function.

**homelab**
- Create `modules/services/game-broker.nix`: `game-broker` CLI (`status | wake | start [preset] | stop`; `openssh wakeonlan jq util-linux`; local flock; `logger -t game-broker`), `programs.ssh.knownHosts.desktop`.
- Modify `modules/sops.nix`: `desktop_broker_ssh_key` (owner withrin, 0400).
- Modify `hosts/core/default.nix`: import.
- Create `docs/game-broker.md`: protocol + runbook.

---

### Stage 0: Facts and physical prep (no config change)

- [x] Record desktop LAN (192.168.0.205), tailnet (100.71.146.43), MAC (`d8:43:ae:70:e6:a8`)
- [ ] Router DHCP reservation for the desktop (**you**)
- [x] BIOS: ErP Ready = Disabled, Resume By PCI-E = Enabled (2026-09-25; needed for Stage 2)
- [ ] Dummy plug into HDMI-A-2 (**you**); then disable it once in COSMIC Displays — it will extend the desktop on first connect. This is imperative cosmic-comp state, not Nix; re-check after COSMIC updates.
- [ ] Verify: `cat /sys/class/drm/card1-HDMI-A-2/{status,modes}` → `connected`, includes `1280x720`

### Stage 1: Streaming baseline (nix-config only)

**Files:**
- Create: `modules/services/sunshine.nix`
- Modify: `hosts/desktop/default.nix`

- [ ] **Step 1: Write the module**

```nix
# modules/services/sunshine.nix — Sunshine game-stream host for Moonlight
#
# The stock NixOS module runs Sunshine as a *user* service wantedBy
# graphical-session.target. COSMIC's cosmic-session.target BindsTo that target
# (as Plasma's session does), so Sunshine starts with any normal graphical
# login and stops with it. Moonlight connects straight to it; nothing else is
# involved.
#
# No prep-cmd anywhere: a stream must never change resolution, monitor layout
# or anything else about the local session. The only app is "Desktop", which
# streams whatever is on screen.
#
# Capture is KMS, which needs CAP_SYS_ADMIN (capSysAdmin installs
# /run/wrappers/bin/sunshine with cap_sys_admin+p). It is the only unattended
# path on NVIDIA under Wayland: portal capture asks for consent interactively,
# and NvFBC is X11-only and needs a CUDA build.
#
# Encoder: Vulkan Video (h264_vulkan / hevc_vulkan), not NVENC. nixpkgs builds
# sunshine without CUDA here, and its NVENC path needs libcuda.so.1 — which
# lives in /run/opengl-driver/lib, is not in the binary's RUNPATH, and cannot be
# supplied through LD_LIBRARY_PATH because the capability wrapper makes the
# process secure-exec. So NVENC fails at startup (`Cannot load libcuda.so.1`)
# and Sunshine falls back to Vulkan, which is still GPU hardware encoding.
# Deliberately left that way until Moonlight testing shows Vulkan is not good
# enough; the first experiment then is a copy of this package with
# /run/opengl-driver/lib added to its RUNPATH (patchelf, no recompile). See
# docs/superpowers/plans/2026-09-25-game-streaming-broker.md.
#
# Firewall: deliberately not openFirewall — that writes the GLOBAL port lists
# and would expose the stream on every interface, the kiosk USB share
# included. The desktop opens the ports per interface instead
# (hosts/desktop/default.nix). The web UI (47990) is opened nowhere and only
# answers localhost (origin_web_ui_allowed = pc): pair from a browser on this
# machine at https://localhost:47990. Sunshine classifies Tailscale's
# 100.64.0.0/10 as "lan", so the default `lan` would have admitted any tailnet
# device had the port been open.
#
# Setting `settings` makes the config file authoritative: the web UI can no
# longer change configuration, only pair clients and manage credentials.
{...}: {
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = false;
    settings = {
      capture = "kms";
      origin_web_ui_allowed = "pc";
      # Already the default; stated so it cannot drift on silently.
      upnp = "disabled";
    };
    applications.apps = [{name = "Desktop";}];
  };
}
```

- [ ] **Step 2: Import it and open ports per interface in `hosts/desktop/default.nix`**

Header `{...}: {` → a `let` binding the port set once (as built — assigning the whole `networking.firewall.interfaces` attrset collided with the existing `interfaces."enp45s0f3u2u2c2"` path in the same file):

```nix
{...}: let
  # See the Sunshine firewall comment further down.
  sunshinePorts = {
    allowedTCPPorts = [47984 47989 48010];
    allowedUDPPorts = [47998 47999 48000 48002 48010];
  };
in {
```

```diff
     ../../modules/services/homelab.nix
+    ../../modules/services/sunshine.nix
```

After the `enp45s0f3u2u2c2` firewall block:

```nix
  # Sunshine's stream ports (modules/services/sunshine.nix), on the house LAN
  # and the tailnet only. From the module's offsets on base port 47989:
  # TCP -5/0/21 and UDP 9/10/11/13/21. TCP +1 (47990, the web UI) is left out
  # on purpose. Not the kiosk share: nothing there should stream from here.
  #
  # "LAN" is looser than it looks: core is a Tailscale subnet router for
  # 192.168.0.0/24 and SNATs routed traffic, so a tailnet device using that
  # route arrives on enp42s0 as 192.168.0.125. Sunshine's own pairing is the
  # real access control; this only keeps the ports off other segments.
  networking.firewall.interfaces.enp42s0 = sunshinePorts;
  networking.firewall.interfaces.tailscale0 = sunshinePorts;
```

Leave the pre-existing `modules/services/kdeconnect.nix` edit out of the commit.

- [x] **Step 3: Build and review the closure diff** — Sunshine came from the binary cache (no local compile); added only sunshine, its wrapper, `sunshine.conf`, `apps.json`, the user unit (+29.2 MiB); global `allowedTCPPorts` unchanged `[25565 27036 27037 27040]`

```bash
nix build .#nixosConfigurations.desktop.config.system.build.toplevel
nix run nixpkgs#nvd -- diff /run/current-system ./result
```

- [x] **Step 4: Switch** — `sudo nixos-rebuild switch --flake .#desktop`

Impact on the running COSMIC session: no COSMIC/SDDM restart (`display-manager` `restartIfChanged = false`); Sunshine is **not** started by the switch. Brief blips: avahi-daemon restart (`publish.userServices` flips, ~1 s of mDNS), firewall reload (conntrack keeps established flows), udev reload + `uinput` load, wrappers re-run. Not strictly reversible: Sunshine creates `~/.config/sunshine/` (TLS cert/key, `sunshine_state.json`, later credentials/pairings) — survives generation rollback, harmless, delete to reset. New posture: a network-facing daemon with `CAP_SYS_ADMIN` in its permitted set.

- [ ] **Step 5: Validate (no Moonlight needed)**

```bash
ls -l /run/wrappers/bin/sunshine
cosmic-randr list > /tmp/randr-before     # take BEFORE switching, compare after
systemctl --user start sunshine
journalctl --user -u sunshine -b | grep -Ei 'encoder|nvenc|kms|Detected display|RAM'
ss -ltnup | grep -E '4798|4799|4800|4801'
curl -k --max-time 5 https://localhost:47990         # answers
ssh core 'nc -zv -w 5 192.168.0.205 47989'           # succeeds
ssh core 'curl -k --max-time 5 https://192.168.0.205:47990'  # times out
cosmic-randr list | diff /tmp/randr-before -         # unchanged
```

Firewall scoping (matching rules are *expected* — print them and read the interfaces, don't just grep for presence):

```bash
sudo iptables-save | grep -E -- '--dport (47984|47989|48010|47998|47999|48000|48002)\b'
sudo iptables-save | grep -F enp45s0f3u2u2c2       # kiosk share: only 53/67, no Sunshine port
```

Pass: every Sunshine rule carries `-i enp42s0` or `-i tailscale0`, each port appears for both, none without `-i`, 47990 appears nowhere, and the kiosk-share interface lists only 53/67.

**Results (2026-09-25, before commit):**
- [x] Wrapper `/run/wrappers/bin/sunshine` present; `systemctl --user start sunshine` → `active`
- [x] KMS capture (`Screencasting with KMS`); monitors 0/1/2 = HDMI-A-1 / DP-1 / DP-2
- [x] Encoder: **NVENC failed (`Cannot load libcuda.so.1`), fell back to `h264_vulkan` / `hevc_vulkan`**; `av1_vulkan` unsupported on Turing. Harmless warnings: `Mismatch on expected Resolution … 1920x1080 vs 640x480` per monitor, `CAP_SYS_NICE capability is missing`
- [x] Listening TCP 47984, 47989, 47990, 48010 (UDP opens per stream)
- [x] Web UI: `https://localhost:47990` → 307 (login redirect); from core → timeout
- [x] From core: 47989 and 48010 connect
- [x] `cosmic-randr list` identical after start (only output listing order differed)
- [x] Firewall rule scoping (2026-09-25, `iptables-save`): 16 Sunshine rules, each TCP 47984/47989/48010 and UDP 47998/47999/48000/48002/48010 present exactly once per interface, all with `-i enp42s0` or `-i tailscale0`, none unscoped; kiosk share `enp45s0f3u2u2c2` lists only TCP 53, UDP 53/67. 47990 was not in the grep pattern — its absence is shown by the timeout from core. Sunshine's `address_family` defaults to `ipv4`, so there is no IPv6 listener to scope.

- [ ] **Step 6: Autostart** — log out and back in (**you**); `systemctl --user is-active sunshine` → `active`. Repeat once in Plasma.
  - [x] COSMIC (2026-09-25, after reboot): `systemctl --user is-active sunshine` → `active`, encoders found without a manual start
  - [ ] Plasma

- [ ] **Step 7: Client tests (you)** — pair at `https://localhost:47990`; Moonlight over LAN (192.168.0.205) and tailnet (100.71.146.43, laptop off-LAN): Ctrl+Alt+Shift+S stats at 60 fps + host latency, audio, controller. Record the encode numbers here to decide whether Vulkan is adequate or the RPATH/NVENC experiment is needed.
  - [x] Phone, Moonlight, streams (2026-09-25). With three monitors the stream is one KMS output (Monitor 0 = HDMI-A-1 by default); expected for Stage 1 — `output_name` can pick another, and the broker session will use the dummy connector.
  - [x] LAN GPU load, phone client (2026-09-25, `nvidia-smi dmon`, client resolution not recorded): `enc` 41–46 %, `sm` 13–24 %, 24 W, 32 °C, with the GPU parked at idle clocks (mclk 405 / pclk 360 MHz). In a burst where clocks rose to 7000 / 1605 MHz, `enc` fell to ~16 %. A non-zero `enc` column confirms Vulkan Video runs on the NVENC hardware block. Encoder headroom is ample; the open question is whether idle clocks add latency.
  - [x] LAN stats overlay, phone, **1280x720 @ 60** (2026-09-25, desktop idle — typing only): host processing latency ~10 ms average (reported 10.1 / 75 / 10), max spike 75 ms; average network latency 5 ms; 0 dropped frames; decode 8–9 ms (phone side). Borderline rather than bad: ~10 ms host latency is on the high side for a hardware encoder, and the GPU was at idle clocks, which is the likely cause of both the average and the 75 ms spike.
  - [x] Same overlay **during a game** (2026-09-25, Onimusha at 60 fps, phone at 1280x720 @ 60): host processing latency **3.2 min / 5.6 max / 3.7 avg ms**, no visible issues. The idle-desktop ~10 ms / 75 ms spike was idle-clock behaviour and does not occur under load. `nvidia-smi dmon` during the same run: GPU at full clocks (mclk 7000 / pclk 1935 MHz), `sm` 55–74 % (the game), `enc` a steady **13 %**, 119–128 W, 54 °C. **Verdict: Vulkan Video encoding is adequate for Stage 1; the RPATH/NVENC experiment is not needed.**
  - [x] Tailnet (2026-09-25): phone on mobile data → 100.71.146.43 streams. Noticeably more connectivity issues than LAN, as expected on a cellular link. Whether that session was direct or DERP-relayed was not captured — next time run `tailscale status` / `tailscale ping johns-z-fold6` during the stream (`relay "…"` = DERP). Good-quality remote play needs a direct path; not a Stage 1 blocker.
  - [x] Audio (2026-09-25, phone over Moonlight: desktop audio comes through)
  - [ ] Controller through Moonlight (client-side pad → Sunshine's Xbox-style virtual pad via `/dev/uinput`; DS5 intentionally unsupported for now). Not yet tested: the Onimusha run used an Xbox controller plugged into the desktop, which bypasses Sunshine's input path. Test from the real client (the phone is not the normal use case).

- [x] **Step 8: Commit** (2026-09-25, `b23b8f1`; controller test and Plasma autostart deferred) — only if the above pass on Vulkan: record the measured result here, then commit `modules/services/sunshine.nix` + `hosts/desktop/default.nix` by themselves (not `kdeconnect.nix`): `add Sunshine streaming host on the desktop, LAN and tailnet only`. No RPATH-patched package and no uhid rule in this commit.

### Stage 2: Remote power (both repos)

- [x] nix-config: `networking.interfaces.enp42s0.wakeOnLan.enable = true;` (2026-09-25)
- [x] homelab: `game-broker wake` → `wakeonlan -i 192.168.0.255 d8:43:ae:70:e6:a8` (2026-09-25, homelab `4084f51`; deployed, woke the desktop from suspend in 11 s, journal entry under `-t game-broker`)
- [x] After boot and after `nmcli con up "Wired connection 1"`: `sudo ethtool enp42s0 | grep Wake-on` → `g`; `/sys/class/net/enp42s0/device/power/wakeup` → `enabled`. If NM overrides, add `networking.networkmanager.settings.connection."ethernet.wake-on-lan"`.
  - [x] After boot (2026-09-25): `power/wakeup` → `enabled`; `Supports Wake-on: pumbg`, `Wake-on: g`
  - [x] After `nmcli con up "Wired connection 1"` (2026-09-25): still `g` / `enabled` — NM preserves the `.link` setting; no NM override needed
- [x] 5× `systemctl suspend` → wake from core; time to ping (2026-09-25): 5/5, 11–13 s
- [x] 5× `poweroff` → wake from core; once after AC removal
  - [x] `poweroff` (2026-09-25): 5/5, 32–35 s (one extra 0 s run discarded — a slow stop job meant the box hadn't powered off yet when the packet went out; the test's wait before sending was raised to 3 min)
  - [x] after AC removal (2026-09-25, last run in the log): cord pulled until the GPU lights went out, replugged, woke in 33 s — WOL survives AC loss
- [x] ~~If S5 is unreliable, suspend becomes the preferred resting state~~ — S5 is reliable; suspend is only faster (~12 s vs ~33 s to ping)

### Stage 3: Status protocol (both repos, read-only)

- [ ] Same commit as enabling sshd: `sops.age.keyFile = "/home/withrin/.config/sops/age/keys.txt"; sops.age.sshKeyPaths = [];` on the desktop
- [ ] sshd: `openFirewall = false`, port 22 on `enp42s0`/`tailscale0` only, `PasswordAuthentication = false`, `KbdInteractiveAuthentication = false`, `PermitRootLogin = "no"`, `AllowUsers = ["broker-control" "withrin"]`; withrin authorized with the **laptop** key only
- [ ] `broker-control` system user: `restrict,command="…/game-broker-remote",from="192.168.0.125,100.109.198.88" <core key>`; dispatcher implements `status` only; **no sudo rule yet**
- [ ] homelab: sops `desktop_broker_ssh_key`, `knownHosts.desktop`, `game-broker status` validating `protocol.major == 1`
- [ ] Validate: `/run/secrets-for-users/withrin_password` exists after switch; `status` → `local` in COSMIC, `none` at greeter, self SSH session labelled; `ssh … 'status; id'` → `unknown_verb`; `-t`, `-L`, `-D` refused; `withrin` from core refused

### Stage 4: Explicit broker session — NOT YET

- [ ] 4a: units + local `sudo game-broker-ctl start|stop|takeover`
- [ ] 4b: dispatcher mutating verbs + scoped sudo rule for `broker-control`
- [ ] 4c: core CLI `start`/`stop` (status → `boot_id` → start)
- [ ] Tests: happy path (`loginctl show-session`, `systemd-cgls -u session-N.scope`); refusal in COSMIC with nothing changed; lingering Steam → refused; same id twice / parallel → one session; `boot_mismatch`; expired UUIDv7; `timeout 1 ssh … start` then retry; stale stop A vs B → `session_mismatch`; `systemctl kill -s KILL game-broker@X` and `pkill -KILL -u withrin gamescope` → SDDM back, no withrin steam/sunshine/gamescope; reboot mid-session; `takeover` from laptop SSH; Ctrl+Alt+F2 under gamescope; `nixos-rebuild test` during a session; session unit started by hand → skipped by `ExecCondition`, SDDM untouched

### Stage 5: Lifecycle automation — later

Reliable stream/client tracking first (Sunshine has no unauthenticated client count; report `null` until proven), then disconnect grace period, suspend-if-safe (all checks local and immediately before sleep, including inhibitors and excluding the dispatcher's own SSH session), presets, Core daemon, virtual connector/headless experiments, launcher/dashboard.

## Must be confirmed on hardware

- `chvt` + `pam_systemd` yields `Active=yes` for the broker session
- gamescope on NVIDIA 595 honours `-O HDMI-A-2` at 720p60 with three other monitors connected
- Sunshine's KMS display selection for the dummy is stable
- ~~NetworkManager preserves the `.link` WOL setting~~ — confirmed 2026-09-25
- ~~S5 WOL on this board~~ — confirmed 2026-09-25, including after AC loss
- VT switching under gamescope's DRM backend
