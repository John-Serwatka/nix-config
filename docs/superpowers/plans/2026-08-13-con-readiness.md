# Con Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Three working game kiosks — `optiplex`, `optiplex2`, `beelink` — with a functioning booth dashboard and a hardened boot path, in under a week.

**Architecture:** `optiplex2` is a new box, so it gets disko from birth and is installed over the network with `disko-install` rather than waiting on a multi-host installer ISO. It also serves as the rehearsal for the `optiplex` disko migration, which is scheduled **last** so a working kiosk is never the first place a procedure runs. A root-key bootstrap makes a freshly imaged box administrable before it can decrypt any secrets.

**Tech Stack:** NixOS (flake, pinned nixpkgs `e7a3ca8`), disko, sops-nix, Home Manager, systemd-boot, greetd + gamescope, just, alejandra.

**Related:** `docs/superpowers/specs/2026-08-13-booth-and-boot-hardening-design.md` (Spec 1 — Tasks 6 and 7 here supersede its Tasks 2-5).

## Global Constraints

- **Deadline is under one week.** When a step fails, prefer the option that leaves a bootable kiosk over the option that is architecturally cleaner.
- Format with alejandra via `nix fmt`; the gate before every commit is `just ci`.
- Commits are small and behavior-preserving, with short 1–2 line messages.
- Never interpolate a secret's value into a Nix string. Consume secrets only via `config.sops.secrets.<name>.path`.
- **Do not run `nixos-rebuild switch` on the laptop until Task 6 Step 3.** `nix flake check` and `nixos-rebuild build` are safe; `switch` fails on the missing `booth_admin_password`.
- A kiosk update has a **config half and a game half**. When a change touches `modules/services/kiosk.nix`, deploy both or the launcher sits in its retry loop forever.
- All three boxes are powered off as of 2026-08-13. Every hardware step needs someone at the machine.

## Deferred past the con

Multi-host `install-kiosk` (baking every closure into the ISO), ISO provenance
stamping, and the README rewrite. The ISO's offline capability matters at a
venue; all installs in this plan happen at home with network, so `disko-install`
covers it. Revisit after the show.

## Task Ownership

| Task | Who | Needs |
|---|---|---|
| 1. Capture optiplex2 hardware facts | **User** | Box + USB |
| 2. Root-key bootstrap | Agent | — |
| 3. optiplex-common + optiplex2 config | Agent | Task 1 facts |
| 4. Install optiplex2 | **User** | Box + network |
| 5. Deploy a game to optiplex2 | **User** | Box online |
| 6. Booth password, key, third host | **User** + agent | Age key, laptop |
| 7. Boot hardening + deploy all three | Agent + **user** | All boxes |
| 8. Migrate optiplex to disko | **User** | Box, destructive |
| 9. Merge to main | Agent | — |

---

### Task 1: Capture optiplex2's hardware facts

> 🔌 **USER ONLY.** Needs the physical box and the installer USB.

Nothing can be written blind here. `modules/disk/kiosk.nix:26-34` deliberately
gives `diskDevice` no default so an unset value fails evaluation rather than
partitioning whatever happens to be `/dev/sda`.

**Files:** none — this task produces facts consumed by Task 3.

**Interfaces:**
- Produces: the disk device path, the `boot.initrd.availableKernelModules` list, and whether the box is the same Dell model as `optiplex`.

- [ ] **Step 1: Boot the installer USB on optiplex2**

Insert the stick written earlier and boot it. Confirm the boot menu reads
`(withrin nix-config)` — that verifies you grabbed the right stick.

- [ ] **Step 2: Record the target disk**

```bash
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL
```

Write down the whole-disk device for the internal drive — `/dev/sda` for a SATA
SSD, `/dev/nvme0n1` for NVMe. **Not** a partition.

- [ ] **Step 3: Record the hardware config**

```bash
nixos-generate-config --show-hardware-config --no-filesystems
```

`--no-filesystems` matters: disko owns the filesystems, so the generated
`fileSystems` block must not end up in the repo. Copy the
`boot.initrd.availableKernelModules`, `boot.kernelModules`, and the
`hardware.cpu.*.updateMicrocode` line.

- [ ] **Step 4: Confirm network and record the IP**

```bash
ip -brief addr; ping -c2 cache.nixos.org
```

`disko-install` re-evaluates the flake and needs network. If this fails, stop —
Task 4 cannot proceed and the multi-host ISO work comes back onto the critical
path.

- [ ] **Step 5: Hand the facts back**

Paste the outputs of Steps 2-4. Task 3 cannot start without them.

---

### Task 2: Root-key bootstrap

A freshly imaged box cannot decrypt `withrin_password` — its SSH host key is new
and therefore not yet an age recipient in `.sops.yaml`. So withrin has no
password, so `just deploy --ask-sudo-password` cannot sudo, so the box is
unadministrable exactly when you need to adopt it.

Authorizing withrin's key for `root` fixes that: deploys target `root@` and
need no sudo. `hosts/kiosk-common.nix:154-161` already argues withrin is
effectively root on these boxes via `wheel` + `trusted-users`, so this grants
little new. NixOS defaults `PermitRootLogin` to `prohibit-password`, which
permits key auth, so no sshd setting changes.

**Files:**
- Modify: `hosts/kiosk-common.nix` (after the `users.users.withrin` block, currently ending line 112)
- Modify: `justfile` (after the `deploy-build` recipe, currently ending line 189)

**Interfaces:**
- Produces: `root` on every kiosk authorizes withrin's desktop and laptop keys; `just deploy-root <host>` deploys without sudo.

- [ ] **Step 1: Write the failing assertion**

```bash
nix eval --json .#nixosConfigurations.beelink.config.users.users.root.openssh.authorizedKeys.keys
```

- [ ] **Step 2: Confirm it fails**

Expected now: `[]` — root authorizes nothing, so a fresh box is unreachable
except as withrin, who has no password.

- [ ] **Step 3: Add the root keys**

In `hosts/kiosk-common.nix`, directly below the closing `];` of the
`users.users.withrin.openssh.authorizedKeys.keys` list:

```nix
  # Bootstrap path for a freshly imaged box. Until its new SSH host key is added
  # to .sops.yaml, sops cannot decrypt withrin_password — so withrin has no
  # password and cannot sudo, which is what `just deploy` needs. Deploying as
  # root sidesteps that entirely. Grants nothing new: withrin is already wheel
  # and a trusted Nix user here (see nix.settings.trusted-users below).
  # PermitRootLogin defaults to prohibit-password, so this is key-only.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINx1ujbVZk2s/RRjVfqLOyNS4HfV1vTNLLivpFIqP0YI withrin@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1Dul40V/Z3WrED3DXnZY9TDhIWMu0HQz/7n/fsH/0u withrin@laptop"
  ];
```

- [ ] **Step 4: Add the deploy recipe**

In `justfile`, immediately after the `deploy-build` recipe:

```just
# Deploy as root instead of withrin+sudo. For a freshly imaged box whose host
# key is not yet an age recipient: it cannot decrypt withrin_password, so
# withrin has no password to sudo with. Use `deploy` once the box is adopted.
[group('deploy')]
deploy-root host:
    nixos-rebuild switch --flake .#{{ host }} --target-host root@{{ host }}
```

- [ ] **Step 5: Verify it passes**

```bash
nix eval --json .#nixosConfigurations.beelink.config.users.users.root.openssh.authorizedKeys.keys
```

Expected: a two-element list with the desktop and laptop keys.

```bash
just --list | grep deploy-root
```

Expected: the recipe appears.

- [ ] **Step 6: Run the gate**

```bash
just ci
```

- [ ] **Step 7: Commit**

```bash
git add hosts/kiosk-common.nix justfile
git commit -m "feat(kiosk): authorize root key for fresh-box bootstrap

A freshly imaged box cannot decrypt withrin_password, so deploys need
a path that does not require sudo."
```

---

### Task 3: optiplex-common and the optiplex2 host

Two near-identical Dells argue for a shared base. `optiplex-common.nix`
deliberately does **not** import `modules/disk/kiosk.nix` yet — `optiplex` still
has `fileSystems` in its generated `hardware.nix`, and disko defines
`fileSystems` too, so importing it there now is an evaluation conflict. Task 8
moves the import up once `optiplex` is migrated.

`system.stateVersion` stays per-host: `optiplex` is `26.05`, and a box first
installed today is `26.11`.

**Files:**
- Create: `hosts/optiplex-common.nix`
- Create: `hosts/optiplex2/default.nix`
- Create: `hosts/optiplex2/hardware.nix`
- Modify: `hosts/optiplex/default.nix`
- Modify: `flake.nix` (after the `optiplex` entry, currently ending line 62)

**Interfaces:**
- Consumes: Task 1's disk device and kernel module list.
- Produces: `nixosConfigurations.optiplex2`, and `hosts/optiplex-common.nix` holding the shared Intel/thermald/120 Hz base.

- [ ] **Step 1: Write the failing assertion**

```bash
nix eval .#nixosConfigurations.optiplex2.config.networking.hostName
```

- [ ] **Step 2: Confirm it fails**

Expected: `error: attribute 'optiplex2' missing`.

- [ ] **Step 3: Create the shared base**

`hosts/optiplex-common.nix`:

```nix
# hosts/optiplex-common.nix — shared base for the Dell OptiPlex game kiosks
#
# Everything both OptiPlexes agree on. Per-host files carry only what actually
# differs: hostname, stateVersion, the generated hardware.nix, and (once
# migrated) the disk device.
#
# Deliberately does NOT import ../modules/disk/kiosk.nix. `optiplex` still
# declares fileSystems in its generated hardware.nix, and disko declares them
# too — importing it here would be an evaluation conflict until that host is
# migrated. Move the import up once both hosts are disko-managed.
{...}: {
  imports = [
    ./kiosk-common.nix
    ../modules/hardware/graphics.nix
    # Intel thermal throttling daemon — these boxes run a game around the clock.
    ../modules/services/thermald.nix
  ];

  # High-refresh panels commonly advertise 60 Hz as their EDID-preferred mode,
  # and gamescope takes it — which smears on VA. 120 Hz needs a 297 MHz pixel
  # clock, inside HDMI 1.4's 340 MHz limit; 144 Hz (346 MHz) and 240 Hz
  # (594 MHz) need HDMI 2.0 and fall back *silently* if the link cannot carry
  # them, so 120 is the value that holds across panels and cables.
  #
  # Monitors get swapped between these boxes, so verify rather than assume:
  #   journalctl -t kiosk -b | grep "selecting mode"
  myConfig.kiosk.refreshHz = 120;

  # Intel iGPU (VA-API stack and modesetting driver come from graphics.nix).
  myConfig.graphics.vendor = "intel";
}
```

- [ ] **Step 4: Point optiplex at the shared base**

Replace the body of `hosts/optiplex/default.nix` with:

```nix
# hosts/optiplex/default.nix — Dell OptiPlex game kiosk
#
# Shared OptiPlex settings (Intel graphics, thermald, 120 Hz) live in
# ../optiplex-common.nix. Still on its generated hardware.nix rather than disko;
# see that file for why the disko import is not shared yet.
{...}: {
  imports = [
    ./hardware.nix
    ../optiplex-common.nix
  ];

  # Which game runs here is a deploy-time decision (see modules/services/kiosk.nix)
  # and the launcher labels its logs from the deployed directory, so nothing here
  # names a game.

  networking.hostName = "optiplex";

  system.stateVersion = "26.05";
}
```

- [ ] **Step 5: Create optiplex2's hardware.nix**

Paste the values from Task 1 Step 3. If the box is the same model as `optiplex`,
they will match `hosts/optiplex/hardware.nix:17-20` — but **use what the box
reported**, not what the other box has.

`hosts/optiplex2/hardware.nix`:

```nix
# hosts/optiplex2/hardware.nix — from `nixos-generate-config --no-filesystems`
#
# No fileSystems or swapDevices block: disko owns partitioning and filesystems
# for this host (../../modules/disk/kiosk.nix), which is the point — it can be
# reinstalled onto replacement hardware without hand-editing a generated file.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
```

- [ ] **Step 6: Create optiplex2's default.nix**

Replace `/dev/sda` with the device from Task 1 Step 2.

`hosts/optiplex2/default.nix`:

```nix
# hosts/optiplex2/default.nix — second Dell OptiPlex game kiosk
#
# Unlike ../optiplex, this box was provisioned with disko from the start, so it
# imports the declarative disk layout directly and its hardware.nix carries no
# fileSystems block.
{...}: {
  imports = [
    ./hardware.nix
    ../optiplex-common.nix
    ../../modules/disk/kiosk.nix
  ];

  # Confirmed with `lsblk` on the box before installing. `disko-install --disk
  # main <dev>` overrides this at install time if it ever changes.
  myConfig.diskDevice = "/dev/sda";

  networking.hostName = "optiplex2";

  # First installed on 26.11 — do not copy optiplex's 26.05.
  system.stateVersion = "26.11";
}
```

- [ ] **Step 7: Register the host in the flake**

In `flake.nix`, directly after the `optiplex` block:

```nix
      optiplex2 = mkHost {
        hostname = "optiplex2";
        users = ["withrin"];
        homeProfile = "home-kiosk";
        modules = [./hosts/optiplex2/default.nix];
      };
```

- [ ] **Step 8: Verify it passes**

```bash
nix eval .#nixosConfigurations.optiplex2.config.networking.hostName
nix eval .#nixosConfigurations.optiplex2.config.myConfig.diskDevice
nix eval .#nixosConfigurations.optiplex2.config.myConfig.kiosk.refreshHz
```

Expected: `"optiplex2"`, your device path, `120`.

Confirm the refactor did not change `optiplex`. Compare its system derivation
against the one recorded before this task — it should be **identical**, since
`optiplex-common.nix` only relocates settings:

```bash
nix eval --raw .#nixosConfigurations.optiplex.config.system.build.toplevel
```

Expected: `/nix/store/2kx2a7f10w5migy4d9frr9jk7khf0h1q-nixos-system-optiplex-26.11.20260711.e7a3ca8`

If it differs, the refactor changed behavior — find out why before continuing.

- [ ] **Step 9: Confirm the disko script now exists**

```bash
nix eval .#nixosConfigurations.optiplex2.config.system.build.diskoScript --raw >/dev/null && echo OK
```

Expected: `OK`. (The same command against `optiplex` still errors with
`No disks defined` — correct until Task 8.)

- [ ] **Step 10: Run the gate**

```bash
just ci
```

- [ ] **Step 11: Commit**

```bash
git add hosts/optiplex-common.nix hosts/optiplex2 hosts/optiplex/default.nix flake.nix
git commit -m "feat(optiplex2): add second OptiPlex kiosk on disko

Shared OptiPlex settings factored into hosts/optiplex-common.nix."
```

---

### Task 4: Install optiplex2 and adopt it

> 🔌 **USER ONLY.** Destructive to optiplex2's disk. Needs network.

**Files:**
- Modify: `.sops.yaml` (keys list and the `creation_rules` age list)

**Interfaces:**
- Consumes: Task 2's root key, Task 3's `nixosConfigurations.optiplex2`.
- Produces: a running kiosk at hostname `optiplex2` that decrypts secrets and auto-joins the tailnet.

- [ ] **Step 1: Push the config to the USB's copy of the flake**

The ISO carries a **snapshot** of the flake from when it was built, which
predates Task 3. Rather than rebuilding a 6 GiB image, clone the current tree
onto the booted box:

```bash
# on optiplex2, booted from the USB
git clone /etc/nix-config /tmp/nix-config
cd /tmp/nix-config
git pull /path/to/desktop/checkout feat/booth-admin-dashboard
```

Simpler if the desktop is reachable: `git clone withrin@desktop:nix-config /tmp/nix-config`.

- [ ] **Step 2: Install**

```bash
disko-install --flake /tmp/nix-config#optiplex2 --disk main /dev/sda
```

Substitute your device. This partitions, formats, mounts, and installs in one
command. It re-evaluates the flake, which is why network is required.

- [ ] **Step 3: Reboot and confirm it comes up**

Remove the USB and reboot. Expected: it boots to a black screen with the
launcher retrying — `journalctl -t kiosk` shows
`game launcher missing or not executable: /opt/kiosk/current/run.sh — retrying in 10s`.

**That is success.** No game is deployed yet; the config half is done and the
game half comes in Task 5.

- [ ] **Step 4: Confirm the bootstrap path works**

From the desktop:

```bash
ssh root@optiplex2 'hostname; systemctl is-active greetd'
```

Expected: `optiplex2` and `active`. If this fails, Task 2's root key did not
make it into the installed closure — check you installed from a tree that
included it.

- [ ] **Step 5: Read the new box's age key**

```bash
ssh root@optiplex2 'cat /etc/ssh/ssh_host_ed25519_key.pub' | nix run nixpkgs#ssh-to-age
```

Copy the `age1...` output.

- [ ] **Step 6: Add it as a recipient**

In `.sops.yaml`, add to the `keys` list beside the other kiosks (after the
`beelink_host` line):

```yaml
  - &optiplex2_host age1REPLACE_WITH_STEP_5_OUTPUT
```

And add it to the `creation_rules` age list, after `*beelink_host`:

```yaml
          - *optiplex2_host
```

- [ ] **Step 7: Re-encrypt to the new recipient**

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix run nixpkgs#sops -- updatekeys secrets/secrets.yaml
```

- [ ] **Step 8: Deploy so it picks up the secrets**

Still as root — the box cannot decrypt until this deploy lands the re-encrypted
file, so withrin still has no password:

```bash
just deploy-root optiplex2
```

- [ ] **Step 9: Verify decryption and tailnet join**

```bash
ssh root@optiplex2 'systemctl is-active tailscaled; tailscale status | head -3'
ssh withrin@optiplex2 'echo withrin login works'
```

Expected: tailscaled active, the box listed in tailscale status, and the withrin
SSH succeeding. If `tailscale status` shows it unauthenticated, the
`tailscale_authkey` in sops is still the placeholder — mint a real one per
`hosts/kiosk-common.nix:134-141`.

- [ ] **Step 10: Commit**

```bash
git add .sops.yaml secrets/secrets.yaml
git commit -m "feat(secrets): add optiplex2 as an age recipient"
```

---

### Task 5: Deploy a game to optiplex2

> 🔌 **USER ONLY.**

**Files:** none.

**Interfaces:**
- Consumes: a running `optiplex2` from Task 4.
- Produces: a kiosk running a game.

- [ ] **Step 1: Check what the other kiosks are running**

```bash
just kiosk-status optiplex
```

This lists every build in `/opt/kiosk` and which one `current` points at. Use
the same build directory for consistency across the fleet.

- [ ] **Step 2: Deploy the build**

```bash
just kiosk-deploy <local-build-dir> <game-name> optiplex2
```

`<local-build-dir>` must contain an executable `run.sh`. The recipe chmods the
ELF entrypoints, rsyncs into `/opt/kiosk/<game-name>/`, writes `.deploy-info`
provenance, and flips the `current` symlink.

- [ ] **Step 3: Restart the session**

```bash
just kiosk-restart optiplex2
```

- [ ] **Step 4: Verify the game is actually running**

```bash
just kiosk-status optiplex2
ssh withrin@optiplex2 'journalctl -t kiosk -b -n 30 --no-pager'
```

Expected: `live: <game-name>`, and log lines reading `starting <game-name>`
without an immediate `exited with status` following. Confirm visually on the
attached monitor.

- [ ] **Step 5: Confirm the refresh rate took**

```bash
ssh withrin@optiplex2 'journalctl -t kiosk -b | grep "selecting mode"'
```

Expected: 120 Hz. gamescope falls back **silently** if the mode is unavailable
or exceeds the link's bandwidth, so this is worth checking rather than assuming
— see `modules/services/kiosk.nix:130-147`.

---

### Task 6: Booth password, booth key, and the third host

Supersedes Spec 1 Tasks 3-4, extended to cover `optiplex2`. The dashboard's
`HOSTS` array is hardcoded — without this the new kiosk silently never appears.

**Files:**
- Modify: `secrets/secrets.yaml` (user)
- Modify: `hosts/kiosk-common.nix:19`
- Modify: `users/booth-admin/booth-dashboard.nix:17`
- Modify: `users/booth-admin/home.nix:42-45`

**Interfaces:**
- Consumes: Task 4's `optiplex2`.
- Produces: a working dashboard showing all three kiosks.

- [ ] **Step 1: USER — add the password to sops**

Requires the age key; an agent cannot do this.

```bash
mkpasswd -m yescrypt
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix run nixpkgs#sops -- secrets/secrets.yaml
```

Add `booth_admin_password: "$y$..."`. Choose something distinct from
`withrin_password` — booth staff get this one.

- [ ] **Step 2: Verify it landed**

```bash
grep -oE '^[A-Za-z0-9_]+:' secrets/secrets.yaml
```

Expected: includes `booth_admin_password:`.

- [ ] **Step 3: Confirm laptop activation is fixed**

```bash
sudo nixos-rebuild switch --flake .#laptop
```

Expected: succeeds. This currently fails — `booth_admin_password` is declared at
`hosts/laptop/default.nix:45-47` with `neededForUsers = true` and consumed at
`users/booth-admin/default.nix:11`, but has never existed in the store.

- [ ] **Step 4: USER — mint the booth key on the laptop**

As the `booth-admin` user, at the path already configured in
`users/booth-admin/home.nix:30`:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_booth_control -C booth-admin@laptop
cat ~/.ssh/id_ed25519_booth_control.pub
```

The private key stays unmanaged by Home Manager — HM would put it in the
world-readable Nix store.

- [ ] **Step 5: Authorize it**

In `hosts/kiosk-common.nix`, replace line 19:

```nix
  boothAdminPublicKey = null;
```

with the public key from Step 4:

```nix
  boothAdminPublicKey = "ssh-ed25519 AAAA... booth-admin@laptop";
```

Leave the comment block above it intact.

- [ ] **Step 6: Add optiplex2 to the dashboard**

In `users/booth-admin/booth-dashboard.nix`, line 17:

```bash
      HOSTS=(optiplex optiplex2 beelink)
```

In `users/booth-admin/home.nix`, in the `settings` attrset alongside the
existing two entries:

```nix
      optiplex2 = common // {HostName = "optiplex2";};
```

- [ ] **Step 7: Verify the authorization renders correctly**

```bash
nix eval --json \
  .#nixosConfigurations.optiplex2.config.users.users.booth-control.openssh.authorizedKeys.keys
```

Expected: one element beginning
`restrict,command="/nix/store/...-kiosk-remote/bin/kiosk-remote" ssh-ed25519 ...`

The `restrict,command=` prefix is the security boundary. If it is missing, stop
— without it the key grants a full shell.

- [ ] **Step 8: Run the gate and deploy everywhere**

```bash
just ci
just deploy optiplex
just deploy optiplex2
just deploy beelink
sudo nixos-rebuild switch --flake .#laptop
```

All four are required. A missed kiosk reads as `offline` in the dashboard, which
looks like a network fault rather than a missed deploy.

- [ ] **Step 9: Verify end to end**

Log into the laptop as `booth-admin`. Expected: the dashboard auto-starts and
shows all three kiosks `● online`.

Exercise each verb against one kiosk: `status`, `logs`, `restart`, `reboot`,
`poweroff` (power it back on by hand). Then confirm the deny path:

```bash
ssh -T optiplex2 definitely-not-a-verb; echo "exit=$?"
```

Expected: `Command denied` and `exit=64`.

- [ ] **Step 10: Commit**

```bash
git add secrets/secrets.yaml hosts/kiosk-common.nix users/booth-admin
git commit -m "feat(booth-admin): finish wiring and add optiplex2"
```

---

### Task 7: Boot hardening on the kiosks

`boot.loader.systemd-boot.editor = false` already landed in commit `3500bac` but
has **not** been deployed to any machine. This task adds the boot timeout and
gets both onto real hardware.

> ⚠️ **Hardware-test assumption.** systemd-boot documents that with `timeout 0`
> the menu is still reachable by holding a key before systemd-boot launches.
> That has **not** been verified on any of these boxes and can be very tight on
> fast UEFI firmware. Getting it wrong means losing access to the `work`
> specialisation without a USB. Step 4 is a real gate.

**Files:**
- Modify: `hosts/kiosk-common.nix` (above the `specialisation.work.configuration` block)

**Interfaces:**
- Consumes: nothing.
- Produces: `boot.loader.timeout = 0` on all three kiosks.

- [ ] **Step 1: Write the failing assertion**

```bash
for h in optiplex optiplex2 beelink laptop; do
  printf '%s timeout: ' "$h"; nix eval ".#nixosConfigurations.$h.config.boot.loader.timeout"
done
```

- [ ] **Step 2: Confirm it fails**

Expected: all four print `5`. Only the three kiosks should change.

- [ ] **Step 3: Add the timeout**

In `hosts/kiosk-common.nix`, immediately above `specialisation.work.configuration`:

```nix
  # No boot menu at a booth: the default kiosk entry starts immediately. The
  # menu — and with it the `work` specialisation — is still reachable by
  # holding a key at power-on. Verify that on each box before relying on it;
  # if the window is not reliably catchable on this firmware, use 1 instead.
  boot.loader.timeout = 0;
```

No `mkForce` needed — `modules/core/bootloader.nix` does not set `timeout`.

- [ ] **Step 4: Verify scoping, then USER — test on optiplex2 first**

```bash
for h in optiplex optiplex2 beelink laptop; do
  printf '%s timeout: ' "$h"; nix eval ".#nixosConfigurations.$h.config.boot.loader.timeout"
done
```

Expected: `optiplex: 0`, `optiplex2: 0`, `beelink: 0`, `laptop: 5`.

Deploy to **optiplex2 only** — it has no game-day history to lose:

```bash
just deploy optiplex2
```

At the box: reboot and confirm it goes straight to the game. Reboot again
holding a key from power-on and confirm the menu appears and `work` is
selectable. At that menu press `e` and confirm **no** editor appears.

**If the menu is not reachable**, change the value to `1`, redeploy, and confirm.
Do not proceed with a value you could not verify.

- [ ] **Step 5: Deploy the verified value to the other two**

```bash
just deploy optiplex
just deploy beelink
```

Repeat the three checks on each. Firmware differs between the Beelink and the
OptiPlexes, so test rather than assume it carries over.

- [ ] **Step 6: Commit**

```bash
git add hosts/kiosk-common.nix
git commit -m "feat(kiosk): hide the boot menu on the kiosks"
```

---

### Task 8: Migrate optiplex to disko

> 🔥 **USER ONLY. DESTRUCTIVE — wipes a currently-working kiosk.**
>
> Scheduled last on purpose. By now the identical procedure has been run on
> optiplex2 (Task 4), so this is a rehearsed operation rather than a first
> attempt. **Do not start this if optiplex2 and beelink are not both confirmed
> working** — that is your fallback to a two-kiosk show.

The host-key backup in Step 2 is what makes this safe: restoring it preserves
the box's age identity, so `withrin_password` and `tailscale_authkey` keep
decrypting and `.sops.yaml:16` stays valid. Without it you repeat Task 4's
adoption dance on a box that used to work.

**Files:**
- Modify: `hosts/optiplex-common.nix` (add the disko import)
- Modify: `hosts/optiplex/default.nix` (add `myConfig.diskDevice`)
- Modify: `hosts/optiplex/hardware.nix` (delete `fileSystems` and `swapDevices`)

**Interfaces:**
- Consumes: a proven procedure from Task 4.
- Produces: both OptiPlexes disko-managed and reprovisionable.

- [ ] **Step 1: Record the current disk device**

```bash
ssh withrin@optiplex 'lsblk -o NAME,SIZE,TYPE,TRAN,MODEL; findmnt -no SOURCE /'
```

Write down the whole-disk device backing `/`.

- [ ] **Step 2: Back up the host key, the games, and the save data**

```bash
mkdir -p ~/optiplex-backup
ssh root@optiplex 'tar -C /etc/ssh -cf - ssh_host_ed25519_key ssh_host_ed25519_key.pub' \
  > ~/optiplex-backup/hostkey.tar
ssh withrin@optiplex 'tar -C /opt -cf - kiosk' > ~/optiplex-backup/opt-kiosk.tar
ssh root@optiplex 'tar -C /var/lib -cf - kiosk' > ~/optiplex-backup/var-lib-kiosk.tar
ls -la ~/optiplex-backup
```

All three must be non-empty before you wipe anything. `/var/lib/kiosk` holds
save data and the Wine prefix (`modules/services/kiosk.nix:177-180`).

- [ ] **Step 3: Move the disko import into the shared base**

In `hosts/optiplex-common.nix`, add to `imports` and delete the paragraph
explaining why it was absent:

```nix
    ../modules/disk/kiosk.nix
```

In `hosts/optiplex2/default.nix`, remove the now-duplicated
`../../modules/disk/kiosk.nix` line from its `imports` (importing twice is
harmless in Nix, but leaving it is misleading).

- [ ] **Step 4: Set optiplex's disk device**

In `hosts/optiplex/default.nix`, add above `networking.hostName`, using the
device from Step 1:

```nix
  # disko owns this host's partitioning and filesystems, so hardware.nix carries
  # no fileSystems block. Confirmed with `lsblk` on the box.
  myConfig.diskDevice = "/dev/sda";
```

- [ ] **Step 5: Strip the generated filesystems**

In `hosts/optiplex/hardware.nix`, delete the `fileSystems."/"`,
`fileSystems."/boot"`, and `swapDevices` blocks (currently lines 21-35). Keep
the imports, the kernel module lines, `nixpkgs.hostPlatform`, and the microcode
line.

- [ ] **Step 6: Verify before touching hardware**

```bash
nix eval .#nixosConfigurations.optiplex.config.myConfig.diskDevice
nix eval .#nixosConfigurations.optiplex.config.system.build.diskoScript --raw >/dev/null && echo "diskoScript OK"
nix eval --json .#nixosConfigurations.optiplex.config.swapDevices
just ci
```

Expected: your device, `diskoScript OK`, `[]` for swapDevices (disko provides
swap as a partition, not a `swapDevices` entry).

- [ ] **Step 7: Commit before the destructive step**

```bash
git add hosts/optiplex-common.nix hosts/optiplex/default.nix hosts/optiplex/hardware.nix hosts/optiplex2/default.nix
git commit -m "feat(optiplex): manage partitioning with disko"
```

- [ ] **Step 8: USER — wipe and reinstall**

Boot the installer USB on optiplex. Clone the current tree as in Task 4 Step 1,
then:

```bash
disko-install --flake /tmp/nix-config#optiplex --disk main /dev/sda
```

- [ ] **Step 9: Restore the host key before first boot completes**

The install generated a **new** host key. Restore the old one so the box keeps
its age identity:

```bash
# from the desktop, with optiplex still booted from the USB and /mnt mounted
scp ~/optiplex-backup/hostkey.tar root@optiplex-usb:/tmp/
ssh root@optiplex-usb 'tar -C /mnt/etc/ssh -xf /tmp/hostkey.tar && \
  chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key && \
  chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub'
```

Use whatever address the USB-booted box has — it is not yet `optiplex` on the
network.

- [ ] **Step 10: Reboot and confirm secrets still decrypt**

```bash
ssh withrin@optiplex 'echo password login works; systemctl is-active tailscaled'
```

Expected: both succeed **without** re-adopting anything in `.sops.yaml`. That
proves the host-key restore worked. If withrin cannot log in, the restore
failed — fall back to Task 4 Steps 5-8 to re-adopt the new key.

- [ ] **Step 11: Restore the games and save data**

```bash
ssh withrin@optiplex 'tar -C /opt -xf -' < ~/optiplex-backup/opt-kiosk.tar
ssh root@optiplex 'tar -C /var/lib -xf -' < ~/optiplex-backup/var-lib-kiosk.tar
just kiosk-restart optiplex
just kiosk-status optiplex
```

Expected: `live: <game-name>` and the game visibly running.

---

### Task 9: Merge to main

**Files:** none.

- [ ] **Step 1: Confirm all three kiosks are healthy**

```bash
for h in optiplex optiplex2 beelink; do just kiosk-status "$h"; done
```

- [ ] **Step 2: Run the gate**

```bash
just ci
```

- [ ] **Step 3: Merge**

```bash
git checkout main
git merge --no-ff feat/booth-admin-dashboard
just ci
```

- [ ] **Step 4: Confirm nothing drifted**

```bash
for h in optiplex optiplex2 beelink; do
  printf '%s: ' "$h"; nixos-rebuild build --flake ".#$h" >/dev/null 2>&1 && echo OK || echo FAILED
done
```

---

## Fallback positions

Under a one-week deadline, know in advance what you drop:

| If this fails | Drop to |
|---|---|
| optiplex2 has no network for `disko-install` | Bake its closure into the ISO (a day of work), or run the show on two kiosks |
| `timeout = 0` menu unreachable (Task 7) | `timeout = 1` — nearly all the benefit, no lockout risk |
| optiplex migration goes wrong (Task 8) | Reinstall from backups; if that fails, two kiosks plus optiplex2 |
| Booth key or password blocked | Kiosks still run games standalone; drive them with `just kiosk-*` from the laptop instead of the dashboard |

**The last safe stopping point is the end of Task 7.** At that point you have
three working kiosks and a working dashboard. Task 8 is the only step that risks
a machine, and it buys fleet consistency rather than con readiness — if the week
gets tight, cut it.
