# users/withrin/desktop-shortcuts.nix
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  # Keep stable IDs for existing Plasma pins, but inherit each package's URL
  # handlers, file arguments, window matching and desktop actions on upgrades.
  #
  # hideSource additionally shadows the package's own entry with a NoDisplay
  # copy at the same ID, so the alias does not sit next to the original in the
  # application menu. Existing pins on the original ID still launch.
  nativeLaunchers = {
    steam = {
      package = osConfig.programs.steam.package;
      icon = "steam";
    };
    spotify = {
      package = pkgs.spotify;
      icon = "spotify";
    };
    rider = {
      package = pkgs.jetbrains.rider;
      icon = "rider";
    };
    idea = {
      package = pkgs.jetbrains.idea;
      icon = "intellijidea";
    };
    aseprite = {
      package = pkgs.aseprite;
      icon = "aseprite";
    };
    discord = {
      package = pkgs.vesktop;
      sourceName = "vesktop";
      icon = "discord";
    };
    godot = {
      package = config.my.godot.package;
      sourceName = "org.godotengine.Godot${lib.versions.majorMinor config.my.godot.package.version}-mono";
      icon = "godot";
      hideSource = true;
    };
  };
  launchers =
    pkgs.runCommand "workstation-launchers" {
      nativeBuildInputs = [pkgs.desktop-file-utils];
    } (lib.concatStringsSep "\n" (lib.mapAttrsToList (
        name: entry: let
          source = "${entry.package}/share/applications/${entry.sourceName or name}.desktop";
        in
          ''
            install -Dm644 ${source} "$out/share/applications/${name}.desktop"
            desktop-file-edit --set-icon=${entry.icon} "$out/share/applications/${name}.desktop"
            desktop-file-validate "$out/share/applications/${name}.desktop"
          ''
          + lib.optionalString (entry.hideSource or false) ''
            install -Dm644 ${source} "$out/share/applications/${entry.sourceName}.desktop"
            desktop-file-edit --set-key=NoDisplay --set-value=true \
              "$out/share/applications/${entry.sourceName}.desktop"
            desktop-file-validate "$out/share/applications/${entry.sourceName}.desktop"
          ''
      )
      nativeLaunchers));
in {
  # Declares my.godot.package, which the godot alias above is built from.
  imports = [../../modules/home/godot.nix];

  # These entries intentionally override the same IDs in the user profile.
  home.packages = [(lib.hiPrio launchers)];
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
    categories = ["Network" "Utility"];
  };

  xdg.desktopEntries.claude = {
    name = "Claude";
    exec = "brave --app=https://claude.ai";
    icon = "claude";
    terminal = false;
    type = "Application";
    categories = ["Network" "Utility"];
  };
}
