# profiles/home/dev.nix — developer tooling (user-owned, opt-in per user)
#
# Import from a user's home.nix to give that user the dev toolchain:
#   imports = [ ../../profiles/home/dev.nix ];
#
# This is the first slice of the hybrid model: host-level needs stay in
# environment.systemPackages, user-owned tools live in Home Manager profiles.
{pkgs, ...}: {
  # Owns EDITOR and VISUAL: defaultEditor sets both, so the editor is declared
  # by the same profile that installs it.
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Match what bare `pkgs.neovim` gave us: `wrapNeovim neovim-unwrapped {}`
    # has every provider off. Home Manager still defaults these to `true` under
    # home.stateVersion < 26.05, which would drag Ruby and a pynvim Python into
    # the closure for providers nothing here uses.
    withRuby = false;
    withPython3 = false;
  };

  home.packages = with pkgs; [
    # Editors / IDEs
    # kate is not listed: it ships with Plasma (modules/services/desktop.nix).
    jetbrains.idea
    jetbrains.rider
    jetbrains.webstorm

    # Languages
    dotnet-sdk_8
    mono

    # Game development
    godot_4_6-mono
    # godot_4_7-mono   Eventual migration
    butler
    steamcmd

    # Build tooling
    just
    jq

    # CLI utilities
    ripgrep
    fd
    tree
    claude-code
    codex
    github-cli
    git-cliff
  ];

  home.sessionVariables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}/share/dotnet";
  };
}
