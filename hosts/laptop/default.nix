# hosts/laptop/default.nix — laptop machine configuration
{pkgs, ...}: {
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
    ../../modules/programs/communication.nix
    ../../modules/programs/media.nix
    ../../modules/programs/productivity.nix
    ../../modules/programs/utilities.nix

    # Services
    ../../modules/services/audio.nix
    ../../modules/services/desktop.nix
    ../../modules/services/flatpak.nix
    ../../modules/services/steam.nix
    ../../modules/services/syncthing.nix
    ../../modules/services/printing.nix
    ../../modules/services/asusd.nix
    ../../modules/services/thermald.nix

    # Hardware
    ../../modules/hardware/amdgpu.nix
    ../../modules/hardware/vulkan.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/network.nix
  ];

  networking.hostName = "laptop";
  networking.enableManager = true;
  networking.openTCPPorts = [25565];
  services.tailscale.enable = true;

  # Set video drivers
  services.xserver.videoDrivers = ["displaylink" "modesetting"];

  # Enable the DisplayLink Manager service
  systemd.services.dlm.wantedBy = ["multi-user.target"];

  services.asusd.enable = true;
  services.asusd.setPerformanceProfile = true;

  system.stateVersion = "25.05";
}
