# hosts/laptop.nix — laptop-specific system config
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
        ../modules/services/asusd.nix
        ../modules/services/thermald.nix

        # Graphics
        ../modules/hardware/amdgpu.nix

        # Input devices
        ../modules/hardware/network-adapter.nix

        # Output devices
        ../modules/services/audio-pipewire.nix

        # Low-level hardware scan (from your generated config)
        ./laptop-hardware.nix
  ];

  networking.hostName = "laptop";

    # ensure the system user exists
    users.users.withrin = {
        isNormalUser = true;
        extraGroups  = [ "wheel" "networkmanager" "input" ];
  };

  services.asusd.enable = true;
  services.asusd.setPerformanceProfile = true;


  hardware.bluetooth.enable = true;
  services.blueman.enable  = true;

  networking.enableManager    = true;
  networking.openTCPPorts     = [ 25565 ];
  networking.networkmanager.enable = true;

  services.printing.enable = true;



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

  # add laptop-only options (touchpad, battery, etc.) here
}
