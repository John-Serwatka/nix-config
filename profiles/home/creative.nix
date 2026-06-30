# profiles/home/creative.nix — creative / audio tooling (user-owned, opt-in per user)
#
# Import from a user's home.nix to give that user the creative toolchain:
#   imports = [ ../../profiles/home/creative.nix ];
{pkgs, ...}: {
  home.packages = with pkgs; [
    # Audio production
    reaper
    surge-xt

    # Visual art
    aseprite
    krita
    inkscape
  ];
}
