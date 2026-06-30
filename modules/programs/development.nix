# modules/programs/development.nix
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Editors / IDEs
    neovim
    kdePackages.kate
    kdePackages.plasma-browser-integration
    jetbrains.idea
    jetbrains.rider
    jetbrains.webstorm

    # Languages
    dotnet-sdk_8
    mono

    # Game Development
    godot-mono
    butler

    # Release / Build tooling
    just
    jq

    # Utilities
    git
    ripgrep
    fd
    tree

    # Security
    pinentry-gnome3

    # Audio
    reaper
    surge-xt
  ];
}
