# modules/services/kiosk.nix — arcade-style game kiosk session
#
# Boots straight into a game: greetd autologins a dedicated passwordless user
# whose session is a supervising launcher that runs the game fullscreen under
# gamescope and relaunches it whenever it exits or crashes.
#
# greetd spawns default_session through PAM (the NixOS module sets
# startSession = true), so the kiosk user gets a real logind session: systemd
# user instance, XDG_RUNTIME_DIR, PipeWire, and seat-based device access
# (uaccess) all work without extra device groups. Not setting initial_session
# keeps services.greetd.restart at its default `true`, so greetd itself is a
# backstop if the launcher ever dies; the launcher's own loop is the primary
# supervisor.
#
# Game builds are deployed out-of-band: rsync a build into its own directory
# under /opt/kiosk (owned by myConfig.primaryUser, so rsync needs no sudo),
# then point the /opt/kiosk/current symlink at it. `command` always resolves
# through that symlink, so which game a host runs is a deploy-time decision,
# not a host config decision. Launcher logs: `journalctl -t kiosk`.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.myConfig.kiosk;

  # With capSysNice, the gamescope binary exists ONLY at /run/wrappers/bin —
  # the gamescope module deliberately keeps it out of systemPackages then.
  gamescopeBin =
    if config.programs.gamescope.capSysNice
    then "/run/wrappers/bin/gamescope"
    else getExe config.programs.gamescope.package;

  kioskRun = pkgs.writeShellScript "kiosk-run" ''
    # Tag everything for `journalctl -t kiosk`.
    exec &> >(${pkgs.systemd}/bin/systemd-cat -t kiosk)

    # readlink/basename/dirname/sleep, rather than trusting the session PATH.
    export PATH=${makeBinPath [pkgs.coreutils]}:$PATH

    game=${escapeShellArg cfg.command}
    while true; do
      if [[ ! -x "$game" ]]; then
        echo "game launcher missing or not executable: $game — retrying in 10s"
        sleep 10
        continue
      fi

      # Label log lines with the directory the entrypoint actually resolves to
      # — i.e. what /opt/kiosk/current points at — so the name follows whatever
      # was last deployed instead of drifting from a value baked in per host.
      # Resolved every iteration, so a redeploy is picked up without a restart.
      name=$(basename "$(dirname "$(readlink -f "$game")")")

      echo "starting $name"
      ${gamescopeBin} ${escapeShellArgs cfg.gamescopeArgs} -- "$game"
      status=$?
      echo "$name exited with status $status — relaunching in 2s"
      sleep 2
    done
  '';
in {
  options.myConfig.kiosk = {
    enable = mkEnableOption "arcade-style game kiosk session";

    command = mkOption {
      type = types.str;
      default = "/opt/kiosk/current/run.sh";
      description = ''
        Executable entrypoint of the game build (native Linux). Defaults to
        the game-agnostic /opt/kiosk/current/run.sh — deploy a build to its
        own directory under /opt/kiosk and symlink `current` at it, and this
        default needs no per-host override.
      '';
    };

    gamescopeArgs = mkOption {
      type = types.listOf types.str;
      default = ["-f"];
      example = ["-f" "--adaptive-sync"];
      description = "Arguments passed to gamescope ahead of the game command.";
    };

    user = mkOption {
      type = types.str;
      default = "kiosk";
      description = "Dedicated account the kiosk session runs as.";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isNormalUser = true;
      # Persistent writable home for saves/settings/shader caches
      # (e.g. Godot user:// data).
      home = "/var/lib/kiosk";
      createHome = true;
      # No password login — greetd autologin only. No wheel, no Home Manager
      # (deliberately kept out of mkHost's `users` list).
      hashedPassword = "!";
    };

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${kioskRun}";
        user = cfg.user;
      };
    };

    programs.gamescope = {
      enable = true;
      # Lets gamescope renice itself. mkDefault so a host can turn it off if
      # the capability wrapper misbehaves on its hardware (gamescopeBin above
      # follows automatically).
      capSysNice = mkDefault true;
    };

    # Controller udev rules (uaccess) without installing Steam.
    hardware.steam-hardware.enable = true;

    # Game builds are foreign binaries, not Nix packages. Godot exports dlopen
    # their display/audio stack at runtime instead of linking it, so it never
    # appears in DT_NEEDED (`ldd` on the export shows only glibc) and there is
    # nothing for autoPatchelf to rewrite. nix-ld — enabled globally in
    # modules/core/nix.nix — is what resolves those dlopens, but its default
    # library set is glibc-ish only, so the game fails every display driver in
    # turn and exits immediately:
    #
    #   ERROR: Can't load Xlib dynamically.
    #   WARNING: Can't load the Wayland client library.
    #   ERROR: Unable to create DisplayServer, all display drivers failed.
    #
    # gamescope runs Xwayland, so X11 is the path Godot actually takes here;
    # the Wayland libs are listed so its fallback works too.
    programs.nix-ld.libraries = with pkgs; [
      # X11 (via gamescope's Xwayland). Top-level names — the `xorg.*` set is
      # deprecated in this nixpkgs and warns on eval.
      libx11
      libxcursor
      libxext
      libxfixes
      libxi
      libxinerama
      libxrandr
      libxrender
      libxcb
      # Wayland fallback
      libdecor
      libxkbcommon
      wayland
      # Rendering
      libglvnd
      vulkan-loader
      # Audio — PipeWire provides the PulseAudio interface (services/audio.nix)
      alsa-lib
      libpulseaudio
      # Input hotplug + desktop portals the engine probes on startup
      dbus
      systemd
      # Font rasterisation for anything not using a bundled font
      fontconfig
      freetype

      # GameMaker runner (Horde of Viscount). Unlike the Godot entries above,
      # this engine *links* its libraries — they show up in DT_NEEDED, so the
      # loader aborts at startup if any is missing rather than degrading.
      stdenv.cc.cc.lib # libstdc++.so.6
      zlib # libz.so.1
      libxxf86vm # libXxf86vm.so.1
      libGLU # libGLU.so.1
      openal # libopenal.so.1
      curlWithGnuTls # ships the Debian-compat libcurl-gnutls.so.4 soname
    ];
  };
}
