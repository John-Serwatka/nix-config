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
    ../../modules/programs/utilities.nix

    # Services
    ../../modules/services/audio.nix
    ../../modules/services/desktop.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/ollama.nix
    ../../modules/services/steam.nix
    ../../modules/services/syncthing.nix

    # Hardware
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/vulkan.nix
    ../../modules/hardware/amd-pstate.nix
    ../../modules/hardware/openrgb.nix
    ../../modules/hardware/desktop-input.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/network.nix
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

  networking.hostName = "desktop";
  myConfig.networking.enableManager = true;
  myConfig.networking.openTCPPorts = [25565];

  system.stateVersion = "25.05";
}
