# modules/programs/cli.nix — core command-line tools available on all hosts
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vim
    nano
    git
    wget
    pinentry-gnome3 # GPG passphrase entry (used by gpg-agent)
  ];
}
