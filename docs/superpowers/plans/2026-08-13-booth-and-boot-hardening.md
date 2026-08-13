# Booth Operator Access and Boot Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the systemd-boot root-shell bypass on the kiosks and finish the half-wired booth-admin dashboard so laptop activation stops failing.

**Architecture:** Four small, independent changes to an existing NixOS flake. Two are Nix edits verifiable entirely by `nix eval` (boot hardening). Two are secret-material bootstrap steps that **only the user can perform** — they need an age key and a laptop that this session does not have. No new modules or abstractions; every consumer of the missing secrets already exists in the tree.

**Tech Stack:** NixOS (flake, pinned nixpkgs `e7a3ca8`), sops-nix, Home Manager, systemd-boot, just, alejandra.

**Source spec:** `docs/superpowers/specs/2026-08-13-booth-and-boot-hardening-design.md`

## Global Constraints

- Format with alejandra via `nix fmt`; the gate before every commit is `just ci` (= `nix fmt` + `nix flake check`).
- Commits are small and behavior-preserving, with short 1–2 line messages.
- Never interpolate a secret's value into a Nix string — it would land world-readable in the Nix store. Consume secrets only via `config.sops.secrets.<name>.path`.
- Verify module claims against the pinned nixpkgs (`e7a3ca8`), not from memory.
- `boot.loader.timeout = 0` is an **unverified hardware assumption**. Do not deploy it to both kiosks at once. See Task 2.
- **Do not run `nixos-rebuild switch` on the laptop until Task 3 is complete.** `nix flake check` and `nixos-rebuild build` do not run sops-install-secrets, but `switch` does, and it will fail on the missing `booth_admin_password`.

## Task Ownership

| Task | Who | Why |
|---|---|---|
| 1. Disable editor | Agent | Pure Nix edit, verified by `nix eval` |
| 2. Kiosk boot timeout | Agent edit, **user** physical test | Needs someone at the machine |
| 3. Add sops password | **User only** | Requires the age key at `~/.config/sops/age/keys.txt` |
| 4. Mint booth key | **User** generates, agent edits | Private key must be created on the laptop |
| 5. Deploy + verify | **User** | Needs both kiosks and the laptop |

---

### Task 1: Disable the systemd-boot entry editor

Highest-value change in the plan. `editor = true` lets anyone at a boot menu press `e`, append `init=/bin/sh`, and get root — bypassing SDDM and every password on the box.

Goes in the shared module, not kiosk-scoped: nothing on the desktop or laptop needs the editor either.

**Files:**
- Modify: `modules/core/bootloader.nix`

**Interfaces:**
- Consumes: nothing.
- Produces: `boot.loader.systemd-boot.editor = false` on every host in the flake.

- [ ] **Step 1: Write the failing assertion**

This repo has no unit-test framework. The equivalent red/green cycle is an
`nix eval` assertion that fails before the change and passes after.

Run this and record the output:

```bash
nix eval .#nixosConfigurations.beelink.config.boot.loader.systemd-boot.editor
```

- [ ] **Step 2: Confirm it fails**

Expected right now: `true` — meaning the bypass is open. If this already
prints `false`, stop: someone else changed it and this task is done.

- [ ] **Step 3: Make the change**

In `modules/core/bootloader.nix`, add the `editor` line. The file is currently:

```nix
# modules/core/bootloader.nix — systemd-boot, latest kernel, EFI
# GPU-specific kernel params (e.g. nvidia blacklist) live in their hardware modules.
{pkgs, ...}: {
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
```

Insert after the `configurationLimit` line:

```nix
  # The boot-menu entry editor lets anyone with a keyboard append
  # `init=/bin/sh` and boot to a root shell, bypassing SDDM and every password
  # on the box. That is unacceptable on a kiosk sitting at a public booth, and
  # nothing here needs it, so it is off everywhere rather than kiosk-scoped.
  boot.loader.systemd-boot.editor = false;
```

- [ ] **Step 4: Verify it passes on every host**

```bash
for h in desktop laptop optiplex beelink; do
  printf '%s: ' "$h"
  nix eval --raw ".#nixosConfigurations.$h.config.boot.loader.systemd-boot.editor" \
    --apply 'x: if x then "OPEN (fail)" else "closed"'
  echo
done
```

Expected: `closed` for all four.

- [ ] **Step 5: Run the repo gate**

```bash
just ci
```

Expected: alejandra reformats nothing unexpected, `nix flake check` passes.

- [ ] **Step 6: Commit**

```bash
git add modules/core/bootloader.nix
git commit -m "feat(boot): disable the systemd-boot entry editor

Closes the init=/bin/sh root-shell bypass at the boot menu."
```

---

### Task 2: Reduce boot-menu exposure on the kiosks

Kiosk-scoped, so desktop and laptop keep their 5-second menu.

> ⚠️ **Unverified hardware assumption.** systemd-boot documents that with
> `timeout 0` the menu is still reachable by holding a key before systemd-boot
> launches. That window has **not** been tested on either box and can be very
> tight on fast UEFI firmware. Getting it wrong means losing access to the
> `work` specialisation without a USB. Step 5 is where you find out, and it is
> a real gate — not a formality.

**Files:**
- Modify: `hosts/kiosk-common.nix`

**Interfaces:**
- Consumes: Task 1's hardened bootloader module (already imported at `hosts/kiosk-common.nix:68`).
- Produces: `boot.loader.timeout = 0` on `optiplex` and `beelink` only.

- [ ] **Step 1: Write the failing assertion**

```bash
for h in beelink laptop; do
  printf '%s timeout: ' "$h"
  nix eval ".#nixosConfigurations.$h.config.boot.loader.timeout"
done
```

- [ ] **Step 2: Confirm it fails**

Expected right now: `beelink timeout: 5` and `laptop timeout: 5`. The goal is
to change only the first.

- [ ] **Step 3: Make the change**

In `hosts/kiosk-common.nix`, immediately above the
`specialisation.work.configuration` block (currently line 219), add:

```nix
  # No boot menu at a booth: the default kiosk entry starts immediately. The
  # menu — and with it the `work` specialisation — is still reachable by
  # holding a key at power-on. Verify that on each box before relying on it;
  # if the window is not reliably catchable on this firmware, use 1 instead.
  boot.loader.timeout = 0;
```

No `mkForce` is needed — `modules/core/bootloader.nix` does not set `timeout`,
so there is no conflicting definition.

- [ ] **Step 4: Verify the scoping is right**

```bash
for h in desktop laptop optiplex beelink; do
  printf '%s timeout: ' "$h"
  nix eval ".#nixosConfigurations.$h.config.boot.loader.timeout"
done
```

Expected: `desktop: 5`, `laptop: 5`, `optiplex: 0`, `beelink: 0`.

- [ ] **Step 5: USER — physical test on ONE kiosk only**

Deploy to a single box first, so a bad outcome leaves the other one working:

```bash
just deploy optiplex
```

Then, at the OptiPlex:

1. Reboot it. Confirm it boots straight into the game with no menu.
2. Reboot again, holding a key from the moment power is applied. Confirm the
   boot menu appears and `work` is selectable.
3. At that menu, press `e`. Confirm **no** editor appears (this also
   confirms Task 1 landed on real hardware).

**If step 2 fails** — the menu is not reachable — change the value to `1`,
redeploy, and confirm the menu appears briefly. Do not proceed to the Beelink
with a value you could not verify.

- [ ] **Step 6: USER — deploy the verified value to the second kiosk**

```bash
just deploy beelink
```

Repeat the three checks above on the Beelink. Its firmware differs from the
OptiPlex's, so the key-hold window may behave differently — test it, don't
assume it carries over.

- [ ] **Step 7: Commit**

```bash
git add hosts/kiosk-common.nix
git commit -m "feat(kiosk): hide the boot menu on the kiosks"
```

---

### Task 3: Add `booth_admin_password` to sops

> 🔒 **USER ONLY.** This requires the age key at
> `~/.config/sops/age/keys.txt`, which this session does not have. An agent
> cannot complete this task.

No Nix changes. The declaration (`hosts/laptop/default.nix:45-47`,
`neededForUsers = true`) and the consumer (`users/booth-admin/default.nix:11`,
`hashedPasswordFile`) both already exist. Only the secret itself is missing —
`secrets/secrets.yaml` currently holds just `withrin_password`,
`tailscale_authkey`, and `sops` metadata.

**This is the task that unbreaks laptop activation.** It has no dependency on
Tasks 1, 2, or 4 and can be done at any point.

**Files:**
- Modify: `secrets/secrets.yaml` (encrypted; safe to commit)

**Interfaces:**
- Consumes: nothing.
- Produces: `sops.secrets.booth_admin_password.path` resolves at activation, unblocking Task 5.

- [ ] **Step 1: Confirm the secret is genuinely missing**

```bash
grep -oE '^[A-Za-z0-9_]+:' secrets/secrets.yaml
```

Expected: `withrin_password:`, `tailscale_authkey:`, `sops:` — and no
`booth_admin_password:`.

- [ ] **Step 2: Generate the password hash**

```bash
mkpasswd -m yescrypt
```

Type the booth-operator password when prompted. Choose something **distinct
from `withrin_password`** — this credential gets handed to booth staff.

Copy the resulting hash (it starts with `$y$`).

- [ ] **Step 3: Add it to the encrypted store**

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix run nixpkgs#sops -- secrets/secrets.yaml
```

Add a line alongside the existing keys, pasting the hash from Step 2:

```yaml
booth_admin_password: "$y$j9T$...."
```

Save and exit; sops re-encrypts on write.

- [ ] **Step 4: Verify it landed**

```bash
grep -oE '^[A-Za-z0-9_]+:' secrets/secrets.yaml
```

Expected: now includes `booth_admin_password:`.

- [ ] **Step 5: Verify the existing hosts still decrypt**

Re-encrypting rewrites the file for every recipient, so confirm nothing else
broke:

```bash
just deploy optiplex
```

Expected: activation succeeds. The OptiPlex consumes `withrin_password` and
`tailscale_authkey` from this same file, so a successful switch proves the
re-encryption preserved the other recipients.

> Use `optiplex`, not `beelink`. If Task 2 has already been committed, a deploy
> carries its `boot.loader.timeout` change with it — and Task 2 deliberately
> puts that value on the OptiPlex first, physically verified, before the
> Beelink. Deploying to the Beelink here would push an untested boot timeout to
> the second box and defeat that safeguard.

- [ ] **Step 6: Confirm laptop activation is fixed**

```bash
sudo nixos-rebuild switch --flake .#laptop
```

Expected: succeeds. This is the command that fails today.

- [ ] **Step 7: Commit**

```bash
git add secrets/secrets.yaml
git commit -m "feat(secrets): add booth_admin_password

Unbreaks laptop activation; the secret was declared and consumed but never
added to the store."
```

---

### Task 4: Mint the booth-control key and authorize it

The dashboard's SSH client config is already complete and correct at
`users/booth-admin/home.nix:24-46` — right `User`, right `IdentityFile`,
`BatchMode`, bounded timeouts. Only the key material and the server-side
authorization are missing.

`boothAdminPublicKey = null` at `hosts/kiosk-common.nix:19` makes the
`lib.optional` at lines 183-185 yield an empty `authorizedKeys` list, so
`booth-control` currently authorizes nothing.

**Files:**
- Modify: `hosts/kiosk-common.nix:19`
- Create (user, outside the repo): `~/.ssh/id_ed25519_booth_control` on the laptop

**Interfaces:**
- Consumes: nothing.
- Produces: `booth-control` on both kiosks authorizes the booth key, pinned to the `kiosk-remote` forced command.

- [ ] **Step 1: USER — generate the keypair on the laptop**

Run **as the `booth-admin` user on the laptop**, at exactly the path already
configured in `users/booth-admin/home.nix:30`:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_booth_control -C booth-admin@laptop
```

The private key stays unmanaged by Home Manager by design — HM would place it
in the world-readable Nix store.

- [ ] **Step 2: USER — read out the public key**

```bash
cat ~/.ssh/id_ed25519_booth_control.pub
```

Hand this value to whoever is doing Step 3.

- [ ] **Step 3: Wire it into the config**

In `hosts/kiosk-common.nix`, replace line 19:

```nix
  boothAdminPublicKey = null;
```

with the public key from Step 2, as a string:

```nix
  boothAdminPublicKey = "ssh-ed25519 AAAA... booth-admin@laptop";
```

Leave the surrounding comment block (lines 13-18) intact — it documents how the
key was generated and why `null` was the safe default.

This is a public key, so it is fine in the Nix store. Do **not** put the private
key anywhere in the repo.

- [ ] **Step 4: Verify the authorization renders correctly**

```bash
nix eval --json \
  .#nixosConfigurations.beelink.config.users.users.booth-control.openssh.authorizedKeys.keys
```

Expected: a single-element list whose entry begins with
`restrict,command="/nix/store/...-kiosk-remote/bin/kiosk-remote" ssh-ed25519 AAAA...`

The `restrict,command=` prefix is the security boundary — if it is missing, stop
and fix it before deploying. Without it the key would grant a full shell.

- [ ] **Step 5: Run the repo gate**

```bash
just ci
```

- [ ] **Step 6: Commit**

```bash
git add hosts/kiosk-common.nix
git commit -m "feat(booth-admin): authorize the booth-control key"
```

---

### Task 5: Deploy and verify end to end

> 🔒 **USER ONLY.** Needs both kiosks and the laptop.

**Files:** none — verification only.

**Interfaces:**
- Consumes: Tasks 1-4.
- Produces: a working booth dashboard.

- [ ] **Step 1: Deploy to BOTH kiosks**

```bash
just deploy optiplex
just deploy beelink
```

Both are required. If only one lands, the dashboard shows one kiosk healthy and
one offline — which reads like a network fault rather than a missed deploy.

- [ ] **Step 2: Log in as the booth operator**

On the laptop, log in as `booth-admin` using the password from Task 3.

Expected: the dashboard auto-starts fullscreen in Konsole.

- [ ] **Step 3: Confirm both kiosks report healthy**

Expected: `optiplex` and `beelink` each show `●  online`.

A `◐ degraded` reading means the SSH path works but greetd or the session is
down — a kiosk problem, not a dashboard problem. `offline` means the SSH path
itself failed: check the key from Task 4 reached that box.

- [ ] **Step 4: Exercise every verb**

From the dashboard, against one kiosk, in this order:

1. `status` — already proven by Step 3.
2. `logs` — expect the launcher's output, the same as `journalctl -t kiosk`.
3. `restart` — expect the game to relaunch within a few seconds.
4. `reboot` — expect the box to drop offline, then return healthy.
5. `poweroff` — expect it to drop offline and stay there. **Power it back on by
   hand**; nothing else will.

- [ ] **Step 5: Confirm the deny path**

The forced-command dispatcher must reject anything not in its allowlist:

```bash
ssh -T optiplex definitely-not-a-verb; echo "exit=$?"
```

Expected: `Command denied` on stderr and `exit=64`.

Also confirm it is not a shell:

```bash
ssh -T optiplex; echo "exit=$?"
```

Expected: `Command denied` and `exit=64` — an empty `$SSH_ORIGINAL_COMMAND`
falls through to the `*)` branch at `hosts/kiosk-common.nix:56-59`, not to a
prompt.

- [ ] **Step 6: Update the spec status**

In `docs/superpowers/specs/2026-08-13-booth-and-boot-hardening-design.md`,
change the `**Status:**` line to `Implemented 2026-XX-XX`, recording the actual
date and the `boot.loader.timeout` value that survived Task 2's hardware test
(`0`, or `1` if the key-hold window was not catchable).

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/specs/2026-08-13-booth-and-boot-hardening-design.md
git commit -m "docs(specs): mark booth and boot hardening implemented"
```

---

## Known follow-up, deliberately out of scope

Reinstalling a kiosk regenerates its SSH host key. That breaks the dashboard
via a `known_hosts` mismatch, and because `users/booth-admin/home.nix:36`
combines `StrictHostKeyChecking = "accept-new"` with `BatchMode = true`, it
fails **silently** in the TUI — the kiosk just reads as `offline`.

Nothing in this plan triggers a reinstall. Spec 2 makes reinstalls routine and
must handle this.
