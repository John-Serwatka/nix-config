# modules/services/asusd.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.services.asusd.defaultProfile = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["quiet" "balanced" "performance"]);
    default = null;
    example = "balanced";
    description = "At login, set the ASUS platform profile to this value. Null leaves it untouched.";
  };

  config = lib.mkIf (config.services.asusd.defaultProfile != null) {
    systemd.user.services.set-asus-profile = {
      description = "Set ASUS platform profile to ${config.services.asusd.defaultProfile}";
      wantedBy = ["default.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.asusctl}/bin/asusctl profile set ${config.services.asusd.defaultProfile}";
      };
    };
  };
}
