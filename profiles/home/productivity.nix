# profiles/home/productivity.nix — notes, office, calendar, PIM, and focus tools (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/productivity.nix ];
{pkgs, ...}: {
  home.packages = with pkgs; [
    obsidian
    gnome-pomodoro
    libreoffice-qt-fresh
    # bitwarden-desktop

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
