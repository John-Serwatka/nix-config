# modules/programs/development.nix — system-level dev-adjacent packages
#
# The developer toolchain moved to profiles/home/dev.nix and the audio tools to
# profiles/home/creative.nix. The entries below are kept system-wide pending
# their own reclassification:
#   - git: redundant with cli.nix / programs.git (dedup is a separate task)
#   - plasma-browser-integration: desktop/browser integration, not a dev tool
#   - pinentry-gnome3: GPG passphrase entry (security/system)
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    kdePackages.plasma-browser-integration
    pinentry-gnome3
  ];
}
