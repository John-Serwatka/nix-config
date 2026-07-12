# hosts/desktop/default.nix — desktop machine configuration
{...}: {
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
    ../../modules/programs/hardware-tools.nix
    ../../modules/programs/steam.nix

    # Services
    ../../modules/services/audio.nix
    ../../modules/services/desktop.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/ollama.nix
    ../../modules/services/syncthing.nix
    ../../modules/services/networking.nix

    # Hardware
    ../../modules/hardware/graphics.nix
    ../../modules/hardware/amd-pstate.nix
    ../../modules/hardware/openrgb.nix
    ../../modules/hardware/desktop-input.nix
    ../../modules/hardware/bluetooth.nix
  ];

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/b9d2c837-c3ab-4297-9b12-30e3c0279519";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };

  # Configured users are added to the docker group automatically (modules/core/users.nix).
  virtualisation.docker.enable = true;

  # Trust the self-hosted Caddy private CA (cert lives in ../../certs).
  security.pki.certificates = [
    (builtins.readFile ../../certs/caddy-ca.crt)
  ];

  myConfig.graphics.vendor = "nvidia";

  networking.hostName = "desktop";
  myConfig.networking.enableManager = true;
  myConfig.networking.openTCPPorts = [25565];

  system.stateVersion = "25.05";
}
