# Nix Configuration

This flake contains a multi-host NixOS configuration with Home Manager.

## Users

Each host declares its users once, in `flake.nix`:

```nix
desktop = mkHost {
  hostname = "desktop";
  users = ["withrin"]; # source of truth for this host
  modules = [./hosts/desktop/default.nix];
};
```

That single list (`lib/mkHost.nix`) drives both the system account
(`users/<name>/default.nix`) and the Home Manager profile (`users/<name>/home.nix`).
`home.username` / `home.homeDirectory` are set from it automatically, and
`modules/core/users.nix` exposes `myConfig.users` / `myConfig.primaryUser` so
per-host details follow the list instead of a hardcoded name — Docker group
membership, the owner of `/opt/kiosk`, `nix.settings.trusted-users`, and the
sops age keyFile path all derive from it.

To add a user:

1. Create `users/<name>/` with `default.nix` (system account) and `home.nix`
   (Home Manager) — copy `users/withrin/` as a starting point.
2. Add `<name>` to the host's `users = [ ... ]` in `flake.nix`.
3. Rebuild.

Home Manager preserves conflicting local files as `<file>.hm-bak`. If that
backup already exists, it keeps the older copy as `<file>.hm-bak.~1~`, then
`~2~`, and so on, so a desktop app replacing a managed file between rebuilds
neither fails activation nor overwrites an earlier backup.

`mimeapps.list` is the exception: it is declared with `force = true`, so
activation overwrites it instead of backing it up. Plasma rewrites that file
every time "Open with → always" is used, which would otherwise leave a fresh
numbered backup behind on every rebuild. The trade is that a default changed
in the Plasma UI is reverted on the next rebuild — change it in
`users/withrin/home.nix` instead.

## Package ownership

Packages are split on ownership, not on convenience. Host-level needs — drivers,
services, desktop basics — stay system packages under `modules/`. User-owned
tools live in Home Manager profiles under `profiles/home/` (`dev`, `gaming`,
`creative`, `media`, `communication`, `productivity`, `utilities`, `shell`,
`git`) and each user's `home.nix` imports the ones that user actually wants.

That is what makes a second user cheap: `users/booth-admin/home.nix` imports
`shell` and nothing else, so the booth operator's account carries the dashboard
and a usable prompt rather than withrin's nine profiles. A package a host needs
whether or not anyone logs in belongs in a module; anything else belongs in a
profile.

## Plasma toolbar icons

Plasma sometimes pins `/nix/store/.../share/applications/app.desktop` instead of
the stable `applications:app.desktop` ID. Weekly garbage collection removes the
old generation and leaves a blank icon, even though the app is still installed.

Withrin's desktop and laptop profiles import `modules/home/plasma-launchers.nix`.
It repairs these pins at login and whenever Plasma saves panel changes, preserving
the pinned apps and their order. Rebuild with `just rebuild` to install it. For an
existing session, run `plasma-fix-launchers` to repair immediately, or use
`plasma-fix-launchers --dry-run` to preview. The command requires a running Plasma
session and updates it without restarting the desktop. Each repair records the
old and new launcher lists under `~/.local/state/plasma-launchers/`.

The custom icons now sit on copies of the packages' native desktop entries, so
URL/file arguments, window matching and Steam's menu actions survive upgrades.
Godot has a stable `godot.desktop` alias; the repair also migrates versioned Mono
Godot pins to it, and the engine's own versioned entry is hidden so only the
alias shows in the application menu. `my.godot.package`, declared in
`modules/home/godot.nix` and imported by both the dev profile that installs the
engine and the shortcuts file that builds the alias, selects both. It currently
selects `pkgs.godot_4_6-mono`; change that one selection when ready for 4.7 or
4.8. Engine upgrades remain an explicit choice, while patch updates follow the
lock.

## Workstation defaults

Firefox handles ordinary web links and HTML files on both workstations. The
ChatGPT and Claude app windows retain their dedicated Brave launchers.

The laptop also enables KDE Connect through its NixOS module, including the
required TCP/UDP ports 1714–1764. After rebuilding, open KDE Connect Settings and
pair with the phone app on the same network. Thunderbird is installed for the
primary laptop user and handles email links and `.eml` files. Add mail accounts
in Thunderbird; account credentials and profiles remain user-managed. These
additions are scoped to `hosts/laptop/default.nix`.

The old Google Drive rclone mount is disabled. Core's Nextcloud replaces it;
existing rclone credentials, mount contents and local caches are not deleted.
Nextcloud account sign-in and selection of folders to sync remain user settings.

On the ASUS laptop, `asusd` selects **Performance on AC** and **Quiet on battery**,
with CPU energy preferences set to performance and power saving respectively.
The `asus-power-policy` system service sets these defaults at boot and when asusd
restarts, then asusd handles unplugging, plugging in and power changes during
suspend. The old login-time Balanced override and competing
`power-profiles-daemon` are removed. Charge limits and custom fan settings remain
in asusd's writable configuration. Use `asusctl profile get` after plugging or
unplugging to verify the active profile; inspect failures with
`journalctl -u asus-power-policy -u asusd -b`.

## Formatting

```bash
nix fmt .          # format every .nix file in the tree
```

The trailing `.` is not optional. This flake's `formatter` output is Alejandra
itself, and Alejandra with no path argument reads *stdin* — so a bare `nix fmt`
formats nothing and exits with `unexpected end of file` on an empty stdin.
Pass a path (or `nix fmt path/to/file.nix` for one file).

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). Plain
files are never read into the config — anything Nix evaluates ends up in the
world-readable `/nix/store`, so secrets are kept encrypted and decrypted at
activation into `/run/secrets/<name>`.

Setup and usage are documented inline in `modules/core/sops.nix`; recipient keys
live in `.sops.yaml` and encrypted material goes under `secrets/`. Until a key
and secrets file exist the secrets layer is inert, so the config still builds.

`secrets/secrets.yaml` currently holds three entries: `withrin_password` and
`booth_admin_password` (login password hashes, consumed as
`hashedPasswordFile`) and `tailscale_authkey` (the kiosks' unattended-join key).
Each is consumed through a *file-based* option — never interpolated into a Nix
string, which would land it world-readable in the store.

Not every credential can go here: an option has to accept a file path. Syncthing
was the counter-example, and its GUI password leaked into git history before it
was retired — treat anything with no `*File` option as a secret to set out of
band, not one to commit.

## Game kiosks

`optiplex` and `optiplex2` boot straight into a game (`hosts/kiosk-common.nix`,
`modules/services/kiosk.nix`). greetd autologins a passwordless `kiosk` user
whose session is a supervising launcher running the game fullscreen under
gamescope, relaunching it whenever it exits.

The boot menu also carries a `work` specialisation — Plasma 6 + SDDM with the
kiosk force-disabled — for doing maintenance on the box itself.

### The Beelink is `core` now, not a kiosk

The fleet used to be three boxes. The Beelink SER left it: that machine was
reinstalled as **`core`, the homelab server**, and is the house's core
infrastructure now — Caddy, Actual Budget, Uptime Kuma and Dashy today, with the
rest of the Pi's services migrating onto it. It lives on the LAN behind a DHCP
reservation and does not travel to events.

**`core` is not configured from this flake.** It has its own repository, pinned
to stable `nixos-26.05` where this one tracks `nixos-unstable`. There is no
`beelink` host here any more — output, `hosts/beelink/` and age recipient are
all gone.

Desktop and laptop access live in `modules/services/homelab.nix`. It installs the
private Caddy CAs and resolves `core`, `dash.home.arpa` and `status.home.arpa`:
the desktop uses core's LAN address (`192.168.0.125`), while the travelling laptop
uses its Tailscale address (`100.109.198.88`). The laptop needs Tailscale connected
even at home for these names. Recheck the tailnet address if core is removed and
rejoined. Public service domains continue using public DNS.

Use `ssh core` for the host's preferred route, `ssh core-remote` to force
Tailscale, or `ssh core-lan` to force the LAN. All three default to the primary
user and use SSH keepalives. `core-lan` is the way back in on the laptop when
tailscaled is down or the network has no internet: there `core` is a tailnet
address, and an unreachable 100.x hangs rather than failing. All three share
core's single `known_hosts` entry via `HostKeyAlias`. Existing per-user Git
hosts and SSH identities are preserved. Core
must be online, permit SSH over Tailscale and authorize the workstation's public
key (see `lib/ssh-keys.nix`); those server settings belong to core's own repo.
The workstation changes do not enroll an unauthenticated machine: run
`sudo tailscale up` once if needed. Validate with `tailscale ping core`,
`ssh core-remote hostname`, and `https://dash.home.arpa` in Firefox.

### Remote access (Tailscale + LAN)

A kiosk keeps two independent ways in, and uses whichever it can get:

- **Tailnet** — `services.tailscale.enable` in `hosts/kiosk-common.nix`. When the
  box has internet it's reachable from anywhere as `optiplex` / `optiplex2` over
  MagicDNS. `tailscale0` is a trusted interface, so SSH — and therefore
  `just deploy` and `just kiosk-deploy`, which are both SSH — work over the
  tailnet with no extra ports opened. This is how you reach a box at a venue.
- **LAN** — port 22 is already open on the physical NIC (openssh defaults
  `openFirewall = true`), so a box on an offline network with no tailnet is
  still reachable from a machine on the same switch/AP.

Neither depends on the other being up. First join is unattended: an auth key in
SOPS (`tailscale_authkey`) is wired to `services.tailscale.authKeyFile`, so a
fresh box joins on first boot. The key is read only while unauthenticated —
once joined, `/var/lib/tailscale` persists and a later expiry/rotation never
drops the node. Both `withrin@desktop` and `withrin@laptop` are authorized.

This is live: `tailscale status` lists `optiplex` and `optiplex2` alongside
`desktop`, `laptop` and `core`, and `secrets.yaml` holds a real reusable key.
A box that is powered off shows as "offline, last seen …" — that is not the same
as never having joined.

Replacing the key (it does not knock joined boxes off — they only read it while
unauthenticated) means minting a **reusable, pre-approved, non-ephemeral** key
in the admin console under Settings → Keys, then:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
    nix run nixpkgs#sops -- secrets/secrets.yaml   # set tailscale_authkey
just deploy optiplex && just deploy optiplex2
```

A brand-new box has to be bootstrapped **from the desktop**: `hosts/kiosk-common.nix`
authorizes `withrin@desktop` and `withrin@laptop`, but a box that has never been
deployed to only has whatever its install image carried.

### Two independent deploys

A kiosk ships in two halves, on separate schedules:

| | what it changes | command |
| --- | --- | --- |
| System config | what the machine *is* | `just deploy <host>` |
| Game build | what the machine *runs* | `just kiosk-deploy <dir> <game> <host>` |

`just deploy` builds locally and copies the closure over SSH, so the kiosks
never compile anything. `just kiosk-deploy` is pure rsync — no Nix, no root, no
reboot: it syncs an export into `/opt/kiosk/<game>/` and flips the
`/opt/kiosk/current` symlink at it.

The hinge is `myConfig.kiosk.command`, which defaults to
`/opt/kiosk/current/run.sh`. The config never names a game, it points at a
symlink — so which game a kiosk runs is a deploy-time decision. The launcher
labels its log lines with the directory that symlink resolves to, re-checked on
every relaunch, so the name follows deploys rather than a per-host setting.

The two halves are independent but not unrelated: **when a change touches the
`/opt/kiosk` layout, ship both.** A game deployed into a layout the running
config doesn't expect doesn't error, it just sits in the launcher's retry loop.
Check with `just kiosk-logs <host>`.

### Bootstrapping a new kiosk

A just-installed kiosk cannot be reached by `just deploy` yet, for two separate
reasons that both have to be cleared once.

**It has no password.** Its SSH host key is not an age recipient in `.sops.yaml`
until you add it, so sops cannot decrypt `withrin_password`, so `withrin` has no
password, so `withrin` cannot `sudo` — which is exactly what `just deploy`
needs. `just deploy-root` goes in as root instead and sidesteps it.

Root SSH is not left open for that. `myConfig.kiosk.rootBootstrapKeys` gates it
and defaults to **off**; the installer ISO turns it on for the system it writes
(`hosts/installer/default.nix` uses `extendModules`), so a box installed from a
stick has the door open and the flake's own config does not.

The bootstrap deploy is therefore self-closing. `just deploy-root` activates the
*flake's* config for that host — the one with the flag off — so that single
activation both gives `withrin` a password and removes the root key it just came
in through. There is nothing to remember and no second step that must not be
forgotten:

```bash
ssh withrin@<host> 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
# → add to .sops.yaml, then:
sops updatekeys secrets/secrets.yaml
just deploy-root <host>        # one-shot: lands the re-keyed secrets AND
                               # removes its own root key in the same activation
just deploy <host>             # from here on; confirms withrin+sudo works
```

**It does not trust unsigned paths.** `nixos-rebuild --target-host` builds
locally, so the paths it pushes are unsigned, and only a trusted user may add
unsigned paths to a store. `hosts/kiosk-common.nix` puts the primary user in
`nix.settings.trusted-users`, but that setting cannot install itself remotely —
so a box that did *not* come from the ISO needs one local rebuild first:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

### Game builds are foreign binaries

Godot exports resolve their display, input and audio libraries with `dlopen` at
runtime rather than linking them, so `ldd` on an export lists only glibc and
there is nothing for autoPatchelf to rewrite. `nix-ld` handles those lookups,
but its default library set carries no X11 or Wayland — without help the game
fails every display driver in turn and exits before opening a window.

`modules/services/kiosk.nix` therefore lists the X11/Wayland/GL/Vulkan/audio
libraries in `programs.nix-ld.libraries`. Any other non-Nix binary dropped into
`/opt/kiosk` needs its own dlopen'd dependencies added there; a
`cannot open shared object file` in `journalctl -t kiosk` points at that list.

## Installer USB

`hosts/installer/default.nix` builds an installer image carrying a **complete
prebuilt kiosk**, so a machine that has never been set up needs no clone, no
network and no credentials:

```bash
just iso                     # -> result/iso/nixos-installer-withrin.iso
lsblk                        # confirm the target device first
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

Boot the stick on the target and run **one command**:

```bash
install-kiosk
```

It lists the disks, makes you type `ERASE`, then partitions, formats and
installs onto the disk the config names (`myConfig.diskDevice`). This is the
normal path — prefer it over anything below.

Nothing is fetched and nothing is evaluated, which is the whole point:

- **No network.** A venue's wifi is not a dependency.
- **No evaluation.** Evaluating the flake needs the nixpkgs / home-manager /
  sops-nix sources, and those are *not* on the image — only `flake.nix` and
  `flake.lock` are. `nixos-install --flake` would try to fetch them.
- **No RAM blowup.** The live installer's `/nix/store` is a tmpfs overlay, so
  substituting the ~13.5 GiB kiosk closure into it OOM-kills the machine.
  Streaming it out of the ISO's squashfs does not.

What it installs is `optiplex2`, extended with
`myConfig.kiosk.rootBootstrapKeys = true` — so the box comes up reachable as
root for its one bootstrap deploy (see [Bootstrapping a new
kiosk](#bootstrapping-a-new-kiosk)).

The flake source is still mounted at `/etc/nix-config` for reference and
post-install work, and your desktop's SSH key is authorized for root on the
*live installer*, so a headless box can be driven from the desktop.

The image is a **snapshot** of the flake at build time — rebuild it whenever the
config it should install has changed.

### Fallback: installing something other than the baked kiosk

`install-kiosk` installs one host onto one disk. A different host, or the same
host onto a different disk, means evaluating the flake — which needs network.

For a disko host (`modules/disk/kiosk.nix`), it is still one command:

```bash
lsblk                        # confirm the device first
disko-install --flake /etc/nix-config#optiplex2 --disk main /dev/sda
```

`--disk main <device>` overrides `myConfig.diskDevice`, so the same config
installs onto whatever disk the replacement hardware presents. `disko-install`
is on the ISO for exactly this.

For a host that is *not* disko-managed, partition by hand first:

```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 1GiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart root ext4 1GiB 100%
mkfs.fat -F32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot && mount /dev/disk/by-label/boot /mnt/boot

nixos-install --flake /etc/nix-config#optiplex
```

The shared kiosk layout is GPT: a 1 GiB ESP at `/boot`, an 8 GiB swap
partition, and ext4 root taking the rest. Filesystems resolve by partition
label (`/dev/disk/by-partlabel/disk-main-*`), never by UUID.

### Which hosts use disko

Only the ones that get reinstalled:

| Host | Filesystems from | Why |
| --- | --- | --- |
| `optiplex2` | disko | Kiosk — provisioned with disko from the start, so it has no `hardware.nix` at all |
| `optiplex` | `hardware.nix` | Kiosk, but already installed; convert at its next reinstall |
| `desktop`, `laptop` | `hardware.nix` | Installed once; disko earns nothing |

`hardware.nix` is not legacy — it is still what `nixos-generate-config` writes
and what upstream expects. Disko is an add-on that pays off in proportion to
how often a machine is reinstalled, and it replaces only the `fileSystems` and
`swapDevices` blocks; kernel modules and microcode stay in `hardware.nix`
either way.

Converting a *running* host is not a rebuild — disko points filesystems at
`/dev/disk/by-partlabel/disk-main-*`, which will not match partitions created
by hand. Do it as part of a reinstall, never as a `nixos-rebuild switch`.

### The hardware.nix caveat (non-disko hosts)

For hosts still using `hardware.nix`, that file holds the filesystem UUIDs of
the specific machine it was generated on, so installing onto *different*
hardware needs a fresh one:

```bash
nixos-generate-config --root /mnt --no-filesystems
```

Copy the result into `hosts/<host>/hardware.nix` and commit it. Skipping this
step is how `hosts/optiplex/hardware.nix` sat as an unbootable placeholder in
git while the real file existed only in the working tree on the machine — the
box could not be deployed to from anywhere else.

## Flatpak

`modules/services/flatpak.nix` enables Flatpak and nothing else — the XDG
desktop portal it needs comes from Plasma, which sets `xdg.portal.enable`, both
portal backends and the portal preference file on every host that imports
`modules/services/desktop.nix`.

Flatpak is deliberately an escape hatch, not the default way to install anything:
declared packages belong in a `profiles/home/*` profile so they are reproducible
and roll back with the generation. Flatpak covers what nixpkgs does not have, or
what needs a vendor build.

Nothing is installed declaratively through it — Flatpak apps are installed by
hand and are not part of the flake:

```bash
flatpak install flathub <app-id>
```

Spotify is *not* one of them: it is a native package in
`profiles/home/media.nix`. If a foreign binary fails to start because it wants a
filesystem layout Nix does not provide, `steam-run <cmd>` is the quick test.
