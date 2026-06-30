# profiles/home/communication.nix — chat and messaging apps (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/communication.nix ];
{pkgs, ...}: {
  home.packages = with pkgs; [
    # discord
    vesktop
  ];
}
