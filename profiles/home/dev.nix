# profiles/home/dev.nix — developer tooling (user-owned, opt-in per user)
#
# Import from a user's home.nix to give that user the dev toolchain:
#   imports = [ ../../profiles/home/dev.nix ];
#
# This is the first slice of the hybrid model: host-level needs stay in
# environment.systemPackages, user-owned tools live in Home Manager profiles.
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Editors / IDEs
    neovim
    kdePackages.kate
    jetbrains.idea
    jetbrains.rider
    jetbrains.webstorm

    # Languages
    dotnet-sdk_8
    mono

    # Game development
    godot-mono
    butler

    # Build tooling
    just
    jq

    # CLI utilities
    ripgrep
    fd
    tree
    claude-code
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}/share/dotnet";
  };
}
