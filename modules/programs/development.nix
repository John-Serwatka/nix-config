# modules/programs/development.nix — editors, IDEs, and developer tooling
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    neovim
    kdePackages.kate
    kdePackages.plasma-browser-integration
    jetbrains.idea
    jetbrains.rider
    jetbrains.webstorm
    dotnet-sdk_8
    mono
    pinentry-gnome3
    godot-mono
    reaper
    surge-xt
  ];
}
