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

  # Host-level gamescope arguments. Per-game ones come from a `gamescope-args`
  # file in the deployed build (read in the loop below).
  baseArgs =
    cfg.gamescopeArgs
    ++ optionals (cfg.refreshHz != null) ["-r" (toString cfg.refreshHz)];

  kioskRun = pkgs.writeShellScript "kiosk-run" ''
    # Tag everything for `journalctl -t kiosk`.
    exec &> >(${pkgs.systemd}/bin/systemd-cat -t kiosk)

    # readlink/basename/dirname/sleep, rather than trusting the session PATH.
    export PATH=${makeBinPath [pkgs.coreutils]}:$PATH

    game=${escapeShellArg cfg.command}
    delay=2
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
      gamedir=$(dirname "$(readlink -f "$game")")
      name=$(basename "$gamedir")

      # A build may ship a `gamescope-args` file with extra flags — typically
      # `-w`/`-h` to declare its native render size so gamescope can upscale it.
      # That belongs with the game rather than the host: which game a kiosk runs
      # is a deploy-time decision, so its display settings have to be too.
      # Word splitting is intended here.
      extra=()
      if [[ -r "$gamedir/gamescope-args" ]]; then
        extra=($(cat "$gamedir/gamescope-args"))
        echo "extra gamescope args from build: ''${extra[*]}"
      fi

      echo "starting $name"
      started=$SECONDS
      ${gamescopeBin} ${escapeShellArgs baseArgs} "''${extra[@]}" -- "$game"
      status=$?
      ran=$((SECONDS - started))

      # Back off when the game dies immediately, so a persistent failure — no
      # monitor attached, a missing library — retries once a minute rather than
      # every two seconds, which otherwise floods the journal and writes a core
      # dump each time. A session that actually ran resets the delay, so an
      # ordinary quit or a redeploy still comes back promptly.
      if [ "$ran" -lt 10 ]; then
        delay=$((delay * 2))
        [ "$delay" -gt 60 ] && delay=60
      else
        delay=2
      fi

      echo "$name exited with status $status after ''${ran}s — relaunching in ''${delay}s"
      sleep "$delay"
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
      default = ["-f" "--force-windows-fullscreen"];
      example = ["-f" "--force-windows-fullscreen" "-S" "fit"];
      description = ''
        Arguments passed to gamescope ahead of the game command.

        `--force-windows-fullscreen` resizes whatever window the game opens to
        the nested display, which a kiosk always wants: `-f` alone only makes
        *gamescope* fullscreen, so a game that opens a small window renders in
        a corner of an otherwise black screen. Games that request fullscreen
        themselves are unaffected.

        Add `-S fit` if a game's aspect ratio ends up stretched.
      '';
    };

    refreshHz = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 120;
      description = ''
        Refresh rate to ask gamescope for, appended as `-r`.

        Left unset, gamescope takes the display's EDID-preferred mode, which is
        commonly 60 Hz even on a high-refresh panel. On VA monitors that shows
        up as smearing or ghosting on moving elements, because their pixel
        response and overdrive are tuned for high refresh.

        This is a property of the monitor attached to a given kiosk, so set it
        per host. Confirm what was actually selected with
        `journalctl -t kiosk -b | grep "selecting mode"` — gamescope falls back
        silently if the mode is unavailable or exceeds the link's bandwidth.
      '';
    };

    enableWine = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Put Wine on the kiosk so a Windows game build can be deployed as a
        fallback when a vendor's Linux export is broken.

        Nothing else changes: which runtime a build uses is decided by the
        `run.sh` that ships inside it, so a Windows build's run.sh calls `wine`
        and a native one does not. Both can sit in /opt/kiosk simultaneously
        with `current` flipped between them.

        Wine creates its prefix under the kiosk user's home on first launch,
        which persists in /var/lib/kiosk. Adds roughly 0.6 GiB to the closure —
        most of Wine's dependencies are already present for the desktop.
      '';
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

    # A kiosk with no monitor attached crash-loops: gamescope cannot find a DRM
    # primary plane and segfaults, so the launcher relaunches it every couple of
    # seconds. That is the right behaviour — plug a display in and it recovers
    # unattended — but each crash writes a core dump, which is unbounded growth
    # from something as ordinary as a loose cable at a venue. Cores are no use
    # here anyway; `journalctl -t kiosk` is how this gets diagnosed.
    systemd.coredump.settings.Coredump.MaxUse = "64M";

    # The `full` variant, not plain wine64: nixpkgs defaults sdlSupport,
    # udevSupport and usbSupport to false, and without udev/SDL wine's winebus
    # cannot enumerate gamepads at all — the game runs but has no controller.
    # Verified by winebus.so linking libudev.so.1 in this build.
    environment.systemPackages = mkIf cfg.enableWine [pkgs.wineWow64Packages.full];

    # Controllers that expose a hidraw node (rather than only evdev, as the
    # xpad-driven Xbox pads do) need the session to hold its ACL; hidraw ships
    # root-only 0600. Harmless where no hidraw node exists, and nothing else on
    # an appliance wants raw HID access.
    services.udev.extraRules = mkIf cfg.enableWine ''
      KERNEL=="hidraw*", TAG+="uaccess"
    '';

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
