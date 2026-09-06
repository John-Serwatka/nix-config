# modules/programs/cli.nix — core command-line tools available on all hosts
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vim # nano is not listed: programs.nano.enable defaults to true
    git
    wget
    just # Recipe runner for this flake's justfile
    unzip # Game builds ship as zips (see `just hov-prep`)
    binutils # readelf/ldd work when inspecting foreign game binaries
  ];

  # No pinentry here. A pinentry binary does nothing on its own — it is picked
  # by gpg-agent, and no host enables one (programs.gnupg.agent is off
  # everywhere and gnupg is not installed). If GPG is ever wanted, set
  # programs.gnupg.agent.enable on the host: that installs gnupg, socket-
  # activates the agent, exports GPG_TTY, and selects the pinentry flavour
  # itself — pinentry-qt under Plasma, curses on the headless kiosks.
}
