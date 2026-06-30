# modules/core/users.nix — central user model
#
# `myConfig.users` is the single source of truth for which users exist on a host;
# it is set by lib/mkHost.nix from the `users` list passed in flake.nix. Both the
# system accounts (users/<name>/default.nix) and the Home Manager profiles
# (users/<name>/home.nix) are generated from that same list.
#
# Anything that needs "the user(s) on this host" should read from here rather than
# hardcoding a name — e.g. Syncthing defaults to `myConfig.primaryUser`, and Docker
# group membership is derived below.
{
  config,
  lib,
  ...
}:
with lib; {
  options.myConfig.users = mkOption {
    type = types.listOf types.str;
    default = [];
    description = "Users configured on this host (set by lib/mkHost.nix).";
  };

  options.myConfig.primaryUser = mkOption {
    type = types.str;
    default =
      if config.myConfig.users == []
      then throw "myConfig.users is empty — every host must list at least one user in its mkHost `users = [ ... ]` (flake.nix)."
      else builtins.head config.myConfig.users;
    description = "The user that single-instance services (e.g. Syncthing) default to.";
  };

  config = {
    assertions = [
      {
        assertion = config.myConfig.users != [];
        message = "myConfig.users is empty — every host must list at least one user in its mkHost `users = [ ... ]` (flake.nix).";
      }
    ];

    # When Docker is enabled on a host, every configured user gets the docker group.
    # NixOS list-merge unions this with each account's base extraGroups.
    users.users = mkIf config.virtualisation.docker.enable (genAttrs config.myConfig.users (_: {
      extraGroups = ["docker"];
    }));
  };
}
