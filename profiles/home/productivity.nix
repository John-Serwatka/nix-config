# profiles/home/productivity.nix — notes, office, calendar, PIM, and focus tools (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/productivity.nix ];
{pkgs, ...}: {
  home.packages = with pkgs; [
    obsidian
    gnome-pomodoro
    libreoffice-qt-stable
    bitwarden-desktop

    # KDE PIM suite
    kdePackages.kalarm
    kdePackages.korganizer
    kdePackages.kmail
    kdePackages.kdepim-addons
    kdePackages.kaccounts-integration
    kdePackages.kaccounts-providers
    kdePackages.akonadi-mime
    # akonadi and kdepim-runtime are not listed: programs.kde-pim installs
    # exactly those two, and plasma6 enables it by default.
  ];
}
