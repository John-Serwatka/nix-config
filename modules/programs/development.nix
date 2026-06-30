# modules/programs/development.nix — system-level dev-adjacent packages
#
# The developer toolchain (editors, IDEs, languages, build/CLI tools) moved to
# the per-user Home Manager profile profiles/home/dev.nix. The entries below are
# kept system-wide pending their own reclassification:
#   - git: redundant with cli.nix / programs.git (dedup is a separate task)
#   - plasma-browser-integration: desktop/browser integration, not a dev tool
#   - pinentry-gnome3: GPG passphrase entry (security/system)
#   - reaper / surge-xt: audio production -> future creative profile
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    kdePackages.plasma-browser-integration
    pinentry-gnome3
    reaper
    surge-xt
  ];
}
