# ASUS owns platform profiles and CPU energy preferences on the laptop.
{
  config,
  pkgs,
  lib,
  ...
}: let
  policy = pkgs.writeShellApplication {
    name = "asus-power-policy";
    runtimeInputs = [config.services.asusd.package pkgs.systemd];
    text = ''
      # Configure the running daemon so its writable config, charge limits and
      # fan settings remain intact. asusd handles later power changes/resume.
      for property in ChangePlatformProfileOnAc ChangePlatformProfileOnBattery PlatformProfileLinkedEpp; do
        busctl --system set-property xyz.ljones.Asusd /xyz/ljones \
          xyz.ljones.Platform "$property" b true
      done

      # CPUEPP uses D-Bus uint32: Performance = 1, Power = 4.
      # https://github.com/OpenGamingCollective/asusctl/blob/6.4.0/rog-platform/src/cpu.rs
      busctl --system set-property xyz.ljones.Asusd /xyz/ljones \
        xyz.ljones.Platform ProfilePerformanceEpp u 1
      busctl --system set-property xyz.ljones.Asusd /xyz/ljones \
        xyz.ljones.Platform ProfileQuietEpp u 4
      asusctl profile set Performance --ac
      asusctl profile set Quiet --battery

      # Setting a preset also changes the active profile. Restore the one for
      # the current power source after configuring both presets.
      on_battery=$(busctl --system get-property org.freedesktop.UPower \
        /org/freedesktop/UPower org.freedesktop.UPower OnBattery)
      case "$on_battery" in
        "b true") asusctl profile set Quiet ;;
        "b false") asusctl profile set Performance ;;
        *) echo "Unexpected UPower OnBattery value: $on_battery" >&2; exit 1 ;;
      esac
    '';
  };
in {
  config = lib.mkIf config.services.asusd.enable {
    # Plasma enables this by default; two profile managers would compete.
    services.power-profiles-daemon.enable = false;
    services.upower.enable = true;

    systemd.services.asus-power-policy = {
      description = "ASUS performance on AC and power saving on battery";
      wantedBy = ["multi-user.target" "asusd.service"];
      requires = ["asusd.service" "upower.service"];
      after = ["asusd.service" "upower.service" "cpufreq.service"];
      partOf = ["asusd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = lib.getExe policy;
      };
    };
  };
}
