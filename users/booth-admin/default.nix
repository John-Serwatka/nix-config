# users/booth-admin/default.nix — system account for the booth operator
#
# A dedicated, low-privilege laptop login whose whole job is the kiosk control
# dashboard (see ./home.nix and ./booth-dashboard.nix). No `wheel`: the booth
# user needs no laptop sudo. `networkmanager` lets an on-site operator repair a
# venue's WiFi from this login without switching to withrin.
{config, ...}: {
  users.users.booth-admin = {
    isNormalUser = true;
    extraGroups = ["networkmanager"];
    hashedPasswordFile = config.sops.secrets.booth_admin_password.path;
  };
}
