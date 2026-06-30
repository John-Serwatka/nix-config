# profiles/home/media.nix — audio and video players (user-owned, opt-in)
#
# Import from a user's home.nix:
#   imports = [ ../../profiles/home/media.nix ];
{pkgs, ...}: {
  home.packages = with pkgs; [
    spotify
    vlc
    kooha
    obs-studio
    ffmpeg
  ];
}
