# users/booth-admin/booth-dashboard.nix — the kiosk control TUI + its launchers
#
# A gum-based terminal dashboard that shows each kiosk's status and drives the
# restricted booth-control dispatcher over SSH (see hosts/kiosk-common.nix). It
# runs fullscreen in Konsole, auto-started on login and also available as a
# normal launcher so closing it doesn't strand the operator on an empty desktop.
{pkgs, ...}: let
  boothDashboard = pkgs.writeShellApplication {
    name = "booth-dashboard";
    runtimeInputs = with pkgs; [openssh gum coreutils];
    text = ''
      # All kiosk operations go through the restricted booth-control dispatcher
      # via `ssh <host> <verb>`. Status output is parsed with a strict field
      # whitelist — never eval/source it — so a misbehaving or compromised kiosk
      # can never run code locally as booth-admin.

      HOSTS=(optiplex beelink)
      SELECTED="''${HOSTS[0]}"
      REFRESH=5 # seconds between idle auto-refreshes

      # Status fields, refreshed into these globals by poll_status.
      BUILD=unknown
      GREETD=unknown
      SESSION=down
      BOOT_ID=unknown
      STATE=offline

      clear_screen() { printf '\033[2J\033[H'; }
      pause() {
        printf '\nPress any key to continue…'
        read -rsn1 _ || true
        printf '\n'
      }

      # poll_status <host> — fill the status globals and STATE
      # (healthy | degraded | offline). Whitelist parsing only.
      poll_status() {
        local host=$1 out key value
        BUILD=unknown
        GREETD=unknown
        SESSION=down
        BOOT_ID=unknown
        STATE=offline
        if ! out=$(ssh -T "$host" status 2>/dev/null); then
          return 0
        fi
        while IFS='=' read -r key value; do
          case "$key" in
            BUILD) BUILD=$value ;;
            GREETD) GREETD=$value ;;
            SESSION) SESSION=$value ;;
            BOOT_ID) BOOT_ID=$value ;;
          esac
        done <<< "$out"
        if [ "$GREETD" = active ] && [ "$SESSION" = active ]; then
          STATE=healthy
        else
          STATE=degraded
        fi
      }

      render() {
        clear_screen
        gum style --bold --border rounded --padding "0 2" "Booth Control"
        local host dot label marker
        for host in "''${HOSTS[@]}"; do
          poll_status "$host"
          case "$STATE" in
            healthy) dot="●"; label="online" ;;
            degraded) dot="◐"; label="degraded (greetd=$GREETD session=$SESSION)" ;;
            *) dot="○"; label="offline" ;;
          esac
          if [ "$host" = "$SELECTED" ]; then marker="▸"; else marker=" "; fi
          printf '\n %s %s %-9s %s\n' "$marker" "$dot" "$host" "$label"
          printf '      live: %s\n' "$BUILD"
        done
        printf '\nSelected: %s\n' "$SELECTED"
        printf '[R]estart  [L]ogs  [D]etails  [B]oot  [P]ower off  [H]ost  [Q]uit\n'
      }

      do_restart() {
        local host=$1 i
        gum spin --title "Restarting $host…" -- ssh -T "$host" restart || true
        # terminate-user only proves the old session died; poll for greetd to
        # bring the replacement game session back.
        for ((i = 0; i < 30; i++)); do
          sleep 1
          poll_status "$host"
          if [ "$STATE" = healthy ]; then
            gum style --bold "Restarted $host — session is back."
            pause
            return 0
          fi
        done
        gum style --bold "$host reachable, but the kiosk session did not return."
        pause
      }

      do_logs() {
        local host=$1 out
        # Capture before paging so a failed SSH doesn't feed the pager garbage.
        if out=$(ssh -T "$host" logs 2>&1); then
          printf '%s\n' "$out" | gum pager || true
        else
          gum style --bold "Unable to retrieve logs from $host."
          printf '%s\n' "$out"
          pause
        fi
      }

      do_details() {
        local host=$1
        poll_status "$host"
        gum style --border rounded --padding "0 2" \
          "host:    $host" \
          "state:   $STATE" \
          "build:   $BUILD" \
          "greetd:  $GREETD" \
          "session: $SESSION" \
          "boot_id: $BOOT_ID"
        pause
      }

      do_reboot() {
        local host=$1 old i
        gum confirm "Reboot $host?" || return 0
        poll_status "$host"
        old=$BOOT_ID
        # A successful reboot drops SSH before a clean exit, so the nonzero
        # status is expected — confirm via a changed BOOT_ID instead.
        ssh -T "$host" reboot >/dev/null 2>&1 || true
        for ((i = 0; i < 60; i++)); do
          sleep 2
          poll_status "$host"
          if [ "$STATE" != offline ] && [ "$BOOT_ID" != unknown ] && [ "$BOOT_ID" != "$old" ] && [ "$STATE" = healthy ]; then
            gum style --bold "$host rebooted — session is back."
            pause
            return 0
          fi
        done
        gum style --bold "$host did not come back within the timeout."
        pause
      }

      do_poweroff() {
        local host=$1 miss=0 i
        gum confirm "Power off $host?" || return 0
        ssh -T "$host" poweroff >/dev/null 2>&1 || true
        # Power-off can't be *proven* over SSH (a network drop looks identical),
        # so require several consecutive unreachable checks and word it honestly.
        for ((i = 0; i < 30; i++)); do
          sleep 2
          if ssh -T "$host" status >/dev/null 2>&1; then
            miss=0
          else
            miss=$((miss + 1))
          fi
          if [ "$miss" -ge 3 ]; then
            gum style --bold "$host is offline after the shutdown request."
            pause
            return 0
          fi
        done
        gum style --bold "$host is still reachable after the shutdown request."
        pause
      }

      choose_host() {
        local pick
        pick=$(printf '%s\n' "''${HOSTS[@]}" | gum choose --header "Select kiosk") || return 0
        if [ -n "$pick" ]; then SELECTED=$pick; fi
      }

      main() {
        local key
        while true; do
          render
          # Idle timeout auto-refreshes the cards; the guard keeps errexit from
          # firing on the nonzero status a timed-out read returns.
          if ! IFS= read -rsn1 -t "$REFRESH" key; then
            continue
          fi
          case "''${key,,}" in
            r) do_restart "$SELECTED" ;;
            l) do_logs "$SELECTED" ;;
            d) do_details "$SELECTED" ;;
            b) do_reboot "$SELECTED" ;;
            p) do_poweroff "$SELECTED" ;;
            h) choose_host ;;
            q) clear_screen; exit 0 ;;
            *) ;;
          esac
        done
      }

      main
    '';
  };

  # Absolute paths — the graphical session's PATH is not trustworthy for autostart.
  dashboardCommand =
    "${pkgs.kdePackages.konsole}/bin/konsole --fullscreen --hide-menubar "
    + "--hide-tabbar -e ${boothDashboard}/bin/booth-dashboard";
in {
  home.packages = [boothDashboard pkgs.kdePackages.konsole];

  # Auto-launch fullscreen when the booth-admin Plasma session starts.
  xdg.configFile."autostart/booth-dashboard.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Booth Dashboard
    Exec=${dashboardCommand}
    Terminal=false
    OnlyShowIn=KDE;
    X-KDE-autostart-after=panel
  '';

  # Normal launcher entry so Q / closing Konsole leaves a way back in.
  xdg.desktopEntries.booth-dashboard = {
    name = "Booth Dashboard";
    comment = "Control the convention game kiosks";
    exec = dashboardCommand;
    terminal = false;
    categories = ["Utility"];
  };
}
