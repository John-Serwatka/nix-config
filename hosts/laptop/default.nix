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

  # Enable the DisplayLink Manager service
  systemd.services.dlm.wantedBy = ["multi-user.target"];

  services.asusd.enable = true;

  # Compressed RAM swap — no on-disk swap partition exists, so this provides
  # OOM headroom for heavy builds without touching the SSD.
  zramSwap.enable = true;

  system.stateVersion = "25.05";
}
