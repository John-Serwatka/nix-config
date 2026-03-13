# modules/programs/productivity.nix — notes, calendar, PIM, and focus tools
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    obsidian
    gnome-pomodoro

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
  ];
}
