# hosts/desktop/default.nix — desktop machine configuration
{ pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../users/withrin/default.nix

    # Core
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/bootloader.nix

    # Programs
    ../../modules/programs/cli.nix
    ../../modules/programs/browsers.nix
    ../../modules/programs/communication.nix
    ../../modules/programs/media.nix
    ../../modules/programs/productivity.nix
    ../../modules/programs/development.nix
    ../../modules/programs/gaming.nix
    ../../modules/programs/utilities.nix

    # Services
    ../../modules/services/audio.nix
    ../../modules/services/desktop.nix
    ../../modules/services/flatpak.nix
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
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      loadModels = [
        "qwen2.5-coder:7b"
        "qwen2.5-coder:1.5b"
        ];
    };

  virtualisation.docker.enable = true;
  users.users.withrin.extraGroups = [ "docker" ];

  networking.hostName       = "desktop";
  networking.enableManager  = true;
  networking.openTCPPorts   = [ 25565 ];

  myConfig.syncthingUser = "withrin";

  system.stateVersion = "25.05";
}
