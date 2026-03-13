# modules/programs/gaming.nix — game launchers, compatibility layers, and tools
# Note: Steam itself is enabled via modules/services/steam.nix (programs.steam.enable)
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    prismlauncher   # Minecraft launcher
    lutris          # Linux game manager
    heroic          # Epic/GOG launcher
    protonup-rs     # Proton-GE updater
    steam
    wine
    winetricks
    vkd3d           # DirectX 12 over Vulkan
  ];
}
