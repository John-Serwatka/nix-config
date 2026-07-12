# hosts/beelink/default.nix — Beelink SER game kiosk (Horde of Viscount)
{...}: {
  imports = [
    ./hardware.nix
    ../kiosk-common.nix
    ../../modules/hardware/amdgpu.nix
    ../../modules/hardware/amd-pstate.nix
    ../../modules/hardware/vulkan.nix
  ];

  myConfig.kiosk.gameName = "Horde of Viscount";

  services.xserver.videoDrivers = ["amdgpu"];

  networking.hostName = "beelink";

  system.stateVersion = "26.05";
}
