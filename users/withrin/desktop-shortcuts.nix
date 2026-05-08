# users/withrin/desktop-shortcuts.nix
{ pkgs, ... }:

{
  home.file.".local/share/icons/hicolor/256x256/apps/discord.png".source =
    ../../assets/icons/Discord-Symbol-Blurple.svg;

  xdg.desktopEntries.discord = {
    name = "Discord";
    exec = "discord";
    icon = "discord";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" ];
  };
}