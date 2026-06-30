# profiles/home/gaming.nix — game launchers, compatibility layers, and tools (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/gaming.nix ];
#
# Note: Steam itself is enabled host-side via modules/services/steam.nix
# (programs.steam.enable), since it needs system-level integration.
{pkgs, ...}: {
  home.packages = with pkgs; [
    prismlauncher # Minecraft launcher
    lutris # Linux game manager
    #heroic          # Epic/GOG launcher
    protonup-rs # Proton-GE updater
    wine
    winetricks
    vkd3d # DirectX 12 over Vulkan
  ];
}
