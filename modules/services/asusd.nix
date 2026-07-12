# modules/services/asusd.nix — ASUS laptop platform-profile helper
#
# The option lives under myConfig.* (not services.asusd.*) so it can never
# collide with a future upstream option of the same name. The daemon itself is
# enabled per-host via the upstream services.asusd.enable.
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.myConfig.asusd.defaultProfile = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["quiet" "balanced" "performance"]);
    default = null;
    example = "balanced";
    description = "At login, set the ASUS platform profile to this value. Null leaves it untouched.";
  };

  config = lib.mkIf (config.myConfig.asusd.defaultProfile != null) {
    systemd.user.services.set-asus-profile = {
      description = "Set ASUS platform profile to ${config.myConfig.asusd.defaultProfile}";
      wantedBy = ["default.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.asusctl}/bin/asusctl profile set ${config.myConfig.asusd.defaultProfile}";
      };
    };
  };
}
