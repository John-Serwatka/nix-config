# hosts/installer/default.nix — self-contained bootable USB installer
#
# Build:  nix build .#installer          (or `just iso`)
# Write:  sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
#
# Boot it on the target and run one command:
#
#   install-kiosk
#
# The image carries the Beelink's *prebuilt* system closure and its *prebuilt*
# disko partitioning script, so installing needs no network and — critically —
# no Nix evaluation on the target. Both of those matter:
#
#   * No network: a venue's wifi is not a dependency.
#   * No evaluation: evaluating the flake needs the nixpkgs/home-manager/
#     sops-nix sources, which are NOT on the image (only flake.nix and
#     flake.lock are). `nixos-install --flake` would try to fetch them.
#   * No RAM blowup: the live installer's /nix/store is a tmpfs overlay, so
#     substituting the 13.5 GiB closure into it OOM-kills the machine. Reading
#     it from the ISO squashfs and streaming to the target disk does not.
#
# The flake source is still mounted at /etc/nix-config for reference and for
# post-install work, but the install path deliberately does not evaluate it.
{
  disko,
  lib,
  modulesPath,
  pkgs,
  self,
  ...
}: let
  # Prebuilt artifacts baked into the image (see isoImage.storeContents below).
  beelinkSystem = self.nixosConfigurations.beelink.config.system.build.toplevel;
  beelinkDisko = self.nixosConfigurations.beelink.config.system.build.diskoScript;

  installKiosk = pkgs.writeShellApplication {
    name = "install-kiosk";
    runtimeInputs = [pkgs.util-linux];
    text = ''
      echo "Installs the Beelink kiosk onto the disk declared in its config"
      echo "(myConfig.diskDevice). EVERYTHING ON THAT DISK WILL BE ERASED."
      echo
      lsblk -o NAME,SIZE,TYPE,TRAN,MODEL
      echo
      read -r -p 'Type ERASE to continue: ' reply
      if [ "''${reply}" != "ERASE" ]; then
        echo "Aborted — nothing was changed."
        exit 1
      fi

      echo "==> partitioning, formatting and mounting"
      ${beelinkDisko}

      echo "==> installing from the USB (no network, no evaluation)"
      nixos-install --root /mnt --system ${beelinkSystem} --no-root-password

      echo
      echo "Done. Reboot and remove the USB stick."
    '';
  };
in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # Everything the offline install needs, embedded in the ISO's squashfs.
  # storeContents is a list option, so this appends to the installer's own
  # entry rather than replacing it.
  isoImage.storeContents = [
    beelinkSystem
    beelinkDisko
  ];

  # Default is "zstd -Xcompression-level 19", which takes far too long over a
  # ~14 GiB store. Level 6 builds in a fraction of the time; the image is a
  # little larger, which does not matter on a 28 GiB stick.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

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
      # The one-command offline install.
      installKiosk
      # Escape hatches if install-kiosk does not fit the situation — e.g. the
      # target disk differs from myConfig.diskDevice, which the prebuilt
      # diskoScript has baked in. `disko-install --disk main <dev>` overrides
      # it, but re-evaluates the flake and so needs network.
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
