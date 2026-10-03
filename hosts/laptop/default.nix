# hosts/laptop/default.nix — laptop machine configuration
{config, ...}: {
  imports = [
    ./hardware.nix

    # Core
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/bootloader.nix
    ../../modules/core/sops.nix

    # Programs
    ../../modules/programs/cli.nix
    ../../modules/programs/browsers.nix
    ../../modules/programs/obs.nix
    ../../modules/programs/hardware-tools.nix
    ../../modules/programs/steam.nix

    # Services
    ../../modules/services/audio.nix
    ../../modules/services/avahi.nix
    ../../modules/services/desktop.nix
    ../../modules/services/cosmic.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/printing.nix
    ../../modules/services/asusd.nix
    ../../modules/services/networking.nix
    ../../modules/services/homelab.nix

    # Hardware
    ../../modules/hardware/graphics.nix
    ../../modules/hardware/amd-pstate.nix
    ../../modules/hardware/bluetooth.nix
  ];

  myConfig.graphics.vendor = "amd";

  networking.hostName = "laptop";
  myConfig.networking.enableManager = true;
  myConfig.networking.openTCPPorts = [25565];
  myConfig.homelab.useTailnet = true;

  # Installs the Plasma integration and opens its TCP/UDP ports (1714–1764).
  programs.kdeconnect.enable = true;

  # Extra personal apps for this host, owned by the primary user's Home
  # Manager profile. Mail accounts and credentials are configured in the UI.
  home-manager.users.${config.myConfig.primaryUser} = {
    programs.thunderbird.enable = true;
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/mailto" = ["thunderbird.desktop"];
      "message/rfc822" = ["thunderbird.desktop"];
    };
  };

  # Login hash for the booth-admin operator account (users/booth-admin). Declared
  # here rather than the shared core/sops.nix so it is laptop-scoped — the kiosks
  # never need to decrypt (or have present in secrets.yaml) a secret only the
  # laptop uses, mirroring how kiosk-common.nix scopes tailscale_authkey.
  # neededForUsers decrypts it early enough for account creation.
  sops.secrets.booth_admin_password = {
    neededForUsers = true;
  };

  # Custom driver list (overrides the graphics.nix default): displaylink for
  # USB docks on top of amdgpu.
  services.xserver.videoDrivers = ["amdgpu" "displaylink" "modesetting"];

  # DisplayLink Manager, started on demand rather than at every boot. 0x17e9 is
  # DisplayLink's USB vendor ID and is shared by every DL-based dock, so this
  # does not need to name a specific one. evdi is an out-of-tree module built
  # against boot.kernelPackages (linuxPackages_latest): if a kernel bump ever
  # outruns evdi, it is this host's build that breaks, and pinning
  # boot.kernelPackages is the way back.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="17e9", TAG+="systemd", ENV{SYSTEMD_WANTS}+="dlm.service"
  '';

  services.asusd.enable = true;

  # asusd owns platform profiles, fans and EPP, but not the MUX. Without
  # supergfxd there is no way to leave the mode the firmware booted in — on
  # this GA402RJ that is AsusMuxDgpu, with the internal eDP wired to the
  # Navi 23 (03:00.0), so the dGPU can never runtime-suspend. supergfxd adds
  # supergfxctl and the graphics section of ROG Control Center; Hybrid and
  # Integrated cut the dGPU out of the display path. Switching modes needs a
  # logout, and anything involving the hardware MUX needs a reboot.
  services.supergfxd.enable = true;

  # Both are already true by default here — fwupd arrives with plasma6 and
  # enableRedistributableFirmware from the graphics stack — but the MT7921 is
  # this machine's only network adapter and the shipped firmware (GA402RJ.319,
  # 2023-06-06) is old enough to want `fwupdmgr refresh && fwupdmgr
  # get-upgrades`. Neither should depend on a desktop module staying imported.
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  # Compressed RAM swap. Still worth having alongside the swapfile below:
  # zramSwap takes priority 5 against the file's default -2, so ordinary
  # paging stays in RAM and the SSD is only touched for hibernation or real
  # pressure.
  zramSwap.enable = true;

  # Hibernation. This platform has no S3 — /sys/power/mem_sleep offers only
  # [s2idle] — so a closed lid on plain suspend keeps drawing, which on this
  # machine means the dGPU too until the MUX leaves AsusMuxDgpu. The swapfile
  # makes suspend-then-hibernate possible instead.
  #
  # @swap is a top-level subvolume alongside @/@home/@nix/@log, mounted
  # without compress= because a swapfile is NODATACOW and cannot be
  # compressed. It is declared here rather than in hardware.nix so it is not
  # lost to a nixos-generate-config run, and so it sits with the swap config
  # it exists for.
  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/1bdf2072-6197-4926-b038-f8daae630169";
    fsType = "btrfs";
    options = ["subvol=@swap" "noatime"];
  };

  # No `size` — the file already exists at 16 GiB (> MemTotal 14.85 GiB), and
  # letting NixOS create it would not apply btrfs's NODATACOW requirement.
  # Recreate with: btrfs filesystem mkswapfile --size 16g /swap/swapfile
  swapDevices = [{device = "/swap/swapfile";}];

  # resume_offset is the swapfile's physical start, from
  #   btrfs inspect-internal map-swapfile -r /swap/swapfile
  # It is tied to this exact file: recreating or defragmenting the swapfile
  # changes it, and a stale value corrupts the resume. Re-run the command and
  # update this if the file is ever rebuilt.
  boot.resumeDevice = "/dev/disk/by-uuid/1bdf2072-6197-4926-b038-f8daae630169";
  boot.kernelParams = ["resume_offset=60335360"];

  # Lid on battery hibernates after 45 min of sleep; on AC it just suspends,
  # since there is nothing to save. Docked is ignored so closing the lid with
  # an external display attached keeps the session up.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  systemd.sleep.settings.Sleep.HibernateDelaySec = "45min";

  system.stateVersion = "25.05";
}
