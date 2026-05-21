# users/withrin/desktop-shortcuts.nix
{ pkgs, ... }:

{
  #
  # Install icons
  #

  # SVG icons
  home.file.".local/share/icons/hicolor/scalable/apps/aseprite.svg".source =
    ../../assets/icons/aseprite.svg;

  home.file.".local/share/icons/hicolor/scalable/apps/chatgpt.svg".source =
    ../../assets/icons/chatgpt.svg;

  home.file.".local/share/icons/hicolor/scalable/apps/discord.svg".source =
    ../../assets/icons/discord.svg;

  home.file.".local/share/icons/hicolor/scalable/apps/godot.svg".source =
    ../../assets/icons/godot.svg;

  home.file.".local/share/icons/hicolor/scalable/apps/intellijidea.svg".source =
    ../../assets/icons/intellijidea.svg;

  home.file.".local/share/icons/hicolor/scalable/apps/rider.svg".source =
    ../../assets/icons/rider.svg;


  # PNG icons
  home.file.".local/share/icons/hicolor/256x256/apps/brave.png".source =
    ../../assets/icons/brave.png;

  home.file.".local/share/icons/hicolor/256x256/apps/claude.png".source =
    ../../assets/icons/claude.png;

  home.file.".local/share/icons/hicolor/256x256/apps/spotify.png".source =
    ../../assets/icons/spotify.png;

  home.file.".local/share/icons/hicolor/256x256/apps/steam.png".source =
    ../../assets/icons/steam.png;


  #
  # Desktop entries
  #

  xdg.desktopEntries.chatgpt = {
    name = "ChatGPT";
    exec = "brave --app=https://chatgpt.com";
    icon = "chatgpt";
    terminal = false;
    type = "Application";
    categories = [ "Network" "Utility" ];
  };

  xdg.desktopEntries.claude = {
    name = "Claude";
    exec = "brave --app=https://claude.ai";
    icon = "claude";
    terminal = false;
    type = "Application";
    categories = [ "Network" "Utility" ];
  };

  xdg.desktopEntries.discord = {
    name = "Discord";
    exec = "discord";
    icon = "discord";
    terminal = false;
    type = "Application";
    categories = [ "Network" "InstantMessaging" ];
  };

  xdg.desktopEntries.spotify = {
    name = "Spotify";
    exec = "spotify";
    icon = "spotify";
    terminal = false;
    type = "Application";
    categories = [ "Audio" "Music" ];
  };

  xdg.desktopEntries.steam = {
    name = "Steam";
    exec = "steam";
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
  };

  xdg.desktopEntries.godot = {
    name = "Godot";
    exec = "godot4";
    icon = "godot";
    terminal = false;
    type = "Application";
    categories = [ "Development" ];
  };

  xdg.desktopEntries.rider = {
    name = "JetBrains Rider";
    exec = "rider";
    icon = "rider";
    terminal = false;
    type = "Application";
    categories = [ "Development" ];
  };

  xdg.desktopEntries.idea = {
    name = "IntelliJ IDEA";
    exec = "idea";
    icon = "intellijidea";
    terminal = false;
    type = "Application";
    categories = [ "Development" ];
  };

  xdg.desktopEntries.aseprite = {
    name = "Aseprite";
    exec = "aseprite";
    icon = "aseprite";
    terminal = false;
    type = "Application";
    categories = [ "Graphics" ];
  };
}
