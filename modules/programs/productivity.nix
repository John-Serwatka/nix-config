# modules/programs/productivity.nix — notes, calendar, PIM, and focus tools
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    obsidian
    gnome-pomodoro
    aseprite
    krita
    inkscape
    #bitwarden-desktop

    # KDE PIM suite
    kdePackages.kalarm
    kdePackages.korganizer
    kdePackages.kmail
    kdePackages.kdepim-addons
    kdePackages.kdepim-runtime
    kdePackages.kaccounts-integration
    kdePackages.kaccounts-providers
    kdePackages.akonadi
    kdePackages.akonadi-mime

    rclone
  ];
}
