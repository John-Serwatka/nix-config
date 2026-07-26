# modules/programs/cli.nix — core command-line tools available on all hosts
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    wget
    just # Recipe runner for this flake's justfile
    pinentry-gnome3 # GPG passphrase entry (used by gpg-agent)
  ];
}
