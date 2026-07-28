# modules/programs/cli.nix — core command-line tools available on all hosts
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    wget
    just # Recipe runner for this flake's justfile
    unzip # Game builds ship as zips (see `just hov-prep`)
    binutils # readelf/ldd work when inspecting foreign game binaries
    pinentry-gnome3 # GPG passphrase entry (used by gpg-agent)
  ];
}
