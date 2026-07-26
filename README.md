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
single-instance services (e.g. Syncthing) and Docker group membership follow the
list instead of a hardcoded name.

To add a user:

1. Create `users/<name>/` with `default.nix` (system account) and `home.nix`
   (Home Manager) — copy `users/withrin/` as a starting point.
2. Add `<name>` to the host's `users = [ ... ]` in `flake.nix`.
3. Rebuild.

Package ownership is currently shared at the system level. The intended next step
is a hybrid model: keep host-level needs (drivers, services, desktop basics) as
system packages, and move user-owned tools (dev/gaming/creative apps) into
per-user Home Manager profiles imported from each user's `home.nix`.

## Formatting

Run `nix fmt` to format all Nix files in the repository using the Alejandra
formatter provided by this flake.

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). Plain
files are never read into the config — anything Nix evaluates ends up in the
world-readable `/nix/store`, so secrets are kept encrypted and decrypted at
activation into `/run/secrets/<name>`.

Setup and usage are documented inline in `modules/core/sops.nix`; recipient keys
live in `.sops.yaml` and encrypted material goes under `secrets/`. Until a key
and secrets file exist the secrets layer is inert, so the config still builds.

The Syncthing GUI password must **not** be committed (a stale one already leaked
in git history — rotate it); set it in the Syncthing web UI instead.

## Game kiosks

`optiplex` and `beelink` boot straight into a game (`hosts/kiosk-common.nix`,
`modules/services/kiosk.nix`). greetd autologins a passwordless `kiosk` user
whose session is a supervising launcher running the game fullscreen under
gamescope, relaunching it whenever it exits.

The boot menu also carries a `work` specialisation — Plasma 6 + SDDM with the
kiosk force-disabled — for doing maintenance on the box itself.

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

`nixos-rebuild --target-host` builds locally, so the paths it pushes are
unsigned, and only a trusted user may add unsigned paths to a store. Root is
trusted by default but cannot log in over SSH here (no key,
`PermitRootLogin prohibit-password`), so `hosts/kiosk-common.nix` adds the
primary user to `nix.settings.trusted-users`.

That setting cannot install itself remotely. Each new kiosk needs **one** local
rebuild on the box before `just deploy` works against it:

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

`hosts/installer/default.nix` builds a NixOS installer image with this flake
already on it, so a machine that has never been set up needs no clone, no
network and no credentials to install from:

```bash
just iso                     # -> result/iso/nixos-installer-withrin.iso
lsblk                        # confirm the target device first
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

The flake lands at `/etc/nix-config` on the booted image, and your SSH key is
authorized for root so a headless box can be installed from the desktop.

Partition, format, mount, then install the host by name:

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

The image is a **snapshot** of the flake at build time — rebuild it whenever the
config it should install has changed.

### Disko hosts install in one command

Hosts that import `modules/disk/kiosk.nix` declare their own partitioning with
[disko](https://github.com/nix-community/disko), so the whole block above
collapses to:

```bash
lsblk                        # confirm the device first
disko-install --flake /etc/nix-config#beelink --disk main /dev/nvme0n1
```

That partitions, formats, mounts and installs. `--disk main <device>` overrides
`myConfig.diskDevice`, so the same config installs onto whatever disk the
replacement hardware presents. `disko-install` is baked into the ISO because
the image has to work without network.

The shared kiosk layout is GPT: a 1 GiB ESP at `/boot`, an 8 GiB swap
partition, and ext4 root taking the rest. Filesystems resolve by partition
label (`/dev/disk/by-partlabel/disk-main-*`), never by UUID.

### Which hosts use disko

Only the ones that get reinstalled:

| Host | Filesystems from | Why |
| --- | --- | --- |
| `beelink` | disko | Kiosk — reprovisioned, spare hardware |
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

## Spotify via Flatpak

If you prefer running Spotify through Flatpak, make sure the Flatpak
service is enabled. This repo sets it in `modules/services/flatpak.nix`:

```nix
services.flatpak.enable = true;
```

After rebuilding, install Spotify with:

```bash
flatpak install flathub com.spotify.Client
```

If you run into issues starting the native `spotify` package, you can try
running it in an FHS environment via:

```bash
steam-run spotify
```

or a custom wrapper such as `buildFHSUserEnv`.
