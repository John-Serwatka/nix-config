# modules/programs/browsers.nix — web browsers
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    brave
    firefox
    chromium
    google-chrome
    kdePackages.plasma-browser-integration # KDE <-> browser integration host
  ];
}
