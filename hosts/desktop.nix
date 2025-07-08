# hosts/desktop.nix — desktop-specific system config
{ config, pkgs, ... }:

{
  imports = [

    # Core settings & shared apps
    ../modules/shared.nix
    ../modules/bootloader.nix
    ../modules/apps/base.nix

    # Gaming stack
    ../modules/apps/games.nix

    # Services
    ../modules/services/flatpak.nix
    ../modules/services/steam.nix
    ../modules/services/xserver-plasma.nix

    # Graphics
    ../modules/hardware/nvidia.nix
    ../modules/hardware/vulkan.nix

    # Misc hardware
    ../modules/hardware/amd-pstate.nix
    ../modules/hardware/openrgb.nix

    # Input devices
    ../modules/hardware/desktop-input.nix
    ../modules/hardware/network-adapter.nix

    # Output devices
    ../modules/services/audio-pipewire.nix

    # Low-level hardware scan (from your generated config)
    ./desktop-hardware.nix
  ];

networking.hostName = "desktop";

hardware.bluetooth.enable = true;
services.blueman.enable  = true;

networking.networkmanager.enable = true;
networking.enableManager    = true;
networking.openTCPPorts     = [ 25565 ];

  # ensure the system user exists
  users.users.withrin = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "input" ];
  };

  system.stateVersion = "25.05";


  services.syncthing = {
    enable           = true;                      # ← start at boot
    user             = "withrin";                 # run under THIS uid
    dataDir          = "/home/withrin/Sync";      # where the synced files live
    configDir        = "/home/withrin/.config/syncthing";
    openDefaultPorts = true;                      # 22000/TCP+UDP, 21027/UDP
  };


  systemd.user.services.syncthingtray = {
    description = "Syncthing tray indicator";

    after      = [ "default.target" "syncthing.service" ];
    wantedBy   = [ "default.target" ];      # auto-start in the session

    serviceConfig = {
       Type      = "simple";
       ExecStart = "${pkgs.syncthingtray}/bin/syncthingtray --wait";
       };
    };

}
