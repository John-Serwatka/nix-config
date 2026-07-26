# hosts/installer/default.nix — bootable USB installer with this flake baked in
#
# Build:  nix build .#installer          (or `just iso`)
# Write:  sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
#
# The point of a custom image is that the flake is already on it: no clone, no
# network, no credentials needed on a machine that has never been set up. It
# lands at /etc/nix-config, so installing a host is:
#
#   nixos-install --flake /etc/nix-config#optiplex
#
# See the README for the full sequence (partitioning still happens by hand —
# see the disko note there).
{
  disko,
  lib,
  modulesPath,
  pkgs,
  self,
  ...
}: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # This flake's own source, copied into the image. `self` is the store path of
  # the tree the ISO was built from, so the image is a snapshot — rebuild it
  # when the config it should install changes.
  environment.etc."nix-config".source = self;

  # Tools for partitioning, and for working with the flake once booted.
  environment.systemPackages =
    (with pkgs; [
      git
      just
      parted
      gptfdisk
      rsync
      # sops/age so a freshly installed host's secrets can be rekeyed on the spot
      age
      sops
    ])
    ++ [
      # Provisioning for disko-managed hosts (modules/disk/kiosk.nix). Baked in
      # because the image has to work with no network — `nix run …#disko-install`
      # would need to fetch it.
      disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
      disko.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  # Needed to install *from* the baked-in flake; the minimal ISO has neither.
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Headless installs: the kiosks are usually on a bench with no keyboard, so
  # allow driving the install over SSH from the desktop. installation-device.nix
  # already enables sshd with PermitRootLogin = yes and blank passwords, but
  # blank passwords cannot authenticate over SSH — hence the key.
  # NOTE: same key as hosts/kiosk-common.nix; worth factoring out if a third
  # copy ever appears.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINx1ujbVZk2s/RRjVfqLOyNS4HfV1vTNLLivpFIqP0YI withrin@desktop"
  ];

  # Wired DHCP is what the kiosk bench has; NetworkManager (from
  # installation-device.nix) covers wireless if needed.
  networking.useDHCP = lib.mkDefault true;

  # Distinguishes it from a stock NixOS ISO in the boot menu and on disk.
  # mkForce because iso-image.nix sets baseName at normal priority.
  image.baseName = lib.mkForce "nixos-installer-withrin";
  isoImage.appendToMenuLabel = " (withrin nix-config)";
}
