# Booth operator access and boot hardening

**Date:** 2026-08-13
**Status:** Approved, not implemented
**Scope:** Spec 1 of 2. Spec 2 covers kiosk provisioning (disko migration, `optiplex2`,
multi-host installer) and is deliberately independent of this one.

## Problem

Two unrelated defects, both live today.

**The booth-admin feature is incomplete and breaks laptop activation.** Commit
`7ef94c6` added the full plumbing for a restricted kiosk control dashboard, but
both of its manual bootstrap steps were skipped. The result is not a
partially-working feature — it is a laptop that is expected to fail to activate.

**The kiosk boot menu offers a root shell.** systemd-boot's entry editor is
enabled, so anyone with a keyboard at a booth can append `init=/bin/sh` and land
as root, bypassing SDDM and every password on the box.

## Verified facts

Established by reading the tree and evaluating the flake, not assumed:

- `booth_admin_password` is declared at `hosts/laptop/default.nix:45-47` with
  `neededForUsers = true` and consumed at `users/booth-admin/default.nix:11` as
  `hashedPasswordFile`. It is **absent** from `secrets/secrets.yaml`, which
  contains only `withrin_password`, `tailscale_authkey`, and `sops` metadata.
- `boothAdminPublicKey = null` at `hosts/kiosk-common.nix:19`, so the
  `lib.optional` at line 183-185 yields an empty `authorizedKeys` list. The
  `booth-control` account exists but authorizes nothing.
- `nix eval` against the pinned nixpkgs (`e7a3ca8`):
  `boot.loader.systemd-boot.editor` → `true`, `boot.loader.timeout` → `5`.
- The `work` specialisation uses SDDM with **no** autologin
  (`modules/services/desktop.nix:6`) and withrin's password comes from sops
  (`users/withrin/default.nix:13`). Selecting `work` therefore reaches a login
  prompt, not a shell — the editor is the only true bypass.
- The dashboard's SSH client config (`users/booth-admin/home.nix:24-46`) is
  already complete and correct: `User = booth-control`, the right `IdentityFile`,
  `BatchMode`, and bounded timeouts. Only the private key is missing.

### Expected-but-not-observed

sops-install-secrets treats a declared-but-missing secret as fatal, so laptop
activation should fail outright. This was **not** reproduced — the age key needed
to decrypt is not available in the working session. The absence of the secret is
certain; the precise failure mode is inferred. Confirm on the laptop before
assuming the fix is complete.

## Goals

1. The booth dashboard works end to end: operator logs into the laptop and drives
   both kiosks.
2. Laptop activation succeeds again.
3. The boot-menu root bypass is closed.
4. Boot-menu exposure at a booth is reduced without locking out the `work`
   specialisation.

## Non-goals

- All provisioning work — disko migration, `optiplex2`, the multi-host installer,
  provenance stamping, README rewrite. That is Spec 2.
- Factoring out the SSH key duplicated between `hosts/installer/default.nix:117`
  and `hosts/kiosk-common.nix:108`. Its own comment sets the threshold at a third
  copy; there are two.
- A local password-gated control surface on the kiosk box itself.
- Giving the `kiosk` session user a password. It stays locked
  (`hashedPassword = "!"`, `modules/services/kiosk.nix:183`); autologin means
  nothing would ever prompt for it.

## Design

### 1. Add `booth_admin_password` to sops

No Nix changes — the declaration and the consumer both already exist. This is
purely the missing secret.

Requires your age key, so it cannot be done unattended:

```bash
mkpasswd -m yescrypt                       # generate the hash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
  nix run nixpkgs#sops -- secrets/secrets.yaml
```

Add `booth_admin_password` alongside the existing keys. This is the
booth-operator password — chosen to be distinct from `withrin_password`, since
it gets handed to booth staff.

**Do this first.** It unbreaks laptop activation on its own, independent of
everything below.

Note the isolation limit: `secrets/secrets.yaml` is encrypted to every recipient
in `.sops.yaml:24-32`, so this password is decryptable by both kiosks, not just
the laptop. That is acceptable for a credential intentionally given to booth
staff. It is *not* acceptable for `withrin_password`, which has the same
exposure — splitting secrets per host class is a separate concern, deliberately
not addressed here.

### 2. Mint the booth-control key

On the laptop, as the `booth-admin` user, matching the path already configured at
`users/booth-admin/home.nix:30`:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_booth_control -C booth-admin@laptop
```

Then set `boothAdminPublicKey` at `hosts/kiosk-common.nix:19` to the `.pub`
contents and deploy to **both** kiosks.

The private key stays unmanaged by Home Manager by design — it is a secret, and
HM would place it in the world-readable Nix store.

### 3. Disable the systemd-boot editor

In `modules/core/bootloader.nix`:

```nix
boot.loader.systemd-boot.editor = false;
```

Placed in the shared module rather than kiosk-scoped: nothing on the desktop or
laptop needs the editor either, and a root-shell bypass is not worth keeping
anywhere. This is the single highest-value change in the spec.

### 4. Reduce boot-menu exposure on the kiosks

In `hosts/kiosk-common.nix`:

```nix
boot.loader.timeout = 0;
```

Kiosk-scoped, so desktop and laptop keep the 5-second menu.

**Hardware-test assumption — read before relying on this.** systemd-boot
documents that with `timeout 0` the menu is still reachable by holding a key
before systemd-boot launches. That window has **not** been verified on either
box, and on fast UEFI hardware it can be very tight. Getting this wrong means
losing access to the `work` specialisation without a USB.

Test on each box before a show. If the menu is not reliably catchable, use
`boot.loader.timeout = 1` instead — nearly all the benefit, no lockout risk.

## Verification

Ordered so each step's failure is unambiguous:

1. `nixos-rebuild switch --flake .#laptop` succeeds. This currently fails
   (expected, see above); succeeding is the signal that step 1 landed.
2. Log in as `booth-admin` on the laptop with the new password.
3. The dashboard auto-starts and shows both kiosks as `healthy` — that alone
   proves the key, the forced command, and the status verb all work.
4. Exercise each verb: `status`, `logs`, `restart`, `reboot`, `poweroff`.
5. Confirm the deny path: `ssh -T optiplex somethingelse` exits 64 with
   `Command denied`.
6. `nix eval .#nixosConfigurations.beelink.config.boot.loader.systemd-boot.editor`
   → `false`.
7. Physically, on each kiosk: press `e` at the boot menu and confirm no editor
   appears; then confirm the menu is still reachable by holding a key at power-on.

## Risks

- **Boot-menu lockout.** Covered above; test before a show, fall back to
  `timeout = 1`.
- **Partial kiosk deploy.** The `boothAdminPublicKey` change must reach both
  kiosks. If only one is deployed, the dashboard shows one healthy and one
  offline, which reads like a network fault rather than a missed deploy.
- **Re-encrypting `secrets.yaml`** rewrites the file for every recipient. Verify
  the existing hosts still decrypt afterwards, not just the laptop.
- **Reinstalling a kiosk will break the dashboard's SSH.** A wipe regenerates the
  box's host key, and `StrictHostKeyChecking = "accept-new"`
  (`users/booth-admin/home.nix:36`) does not override an existing `known_hosts`
  entry — it fails with a mismatch, and `BatchMode` means it fails silently in
  the TUI. Not triggered by this spec, but Spec 2 makes reinstalls routine and
  must handle it.
