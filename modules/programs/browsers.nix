# modules/programs/browsers.nix — web browsers
{pkgs, ...}: {
  # Firefox: daily driver. Enabled through programs.firefox rather than listed
  # in systemPackages, because that option is what builds the *wrapper*.
  # plasma6 (via modules/services/desktop.nix) sets
  #   programs.firefox.nativeMessagingHosts.packages = [ plasma-browser-integration ]
  # and that list only reaches the browser through the wrapper. A raw
  # pkgs.firefox in systemPackages silently has no KDE integration.
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
    };
  };

  # Policies for the Chromium-family browsers below. This module installs no
  # browser — it only writes /etc/{chromium,opt/chrome,brave}/… — and every
  # file it writes is gated behind `enable`. plasma6 already asks for
  # enablePlasmaBrowserIntegration, so without this `enable` the KDE native
  # messaging host is never written at all.
  #
  # Note the asymmetry upstream: the module writes policies for brave but only
  # writes the native messaging host for chromium and google-chrome, so Brave
  # gets the extension forcelist without the KDE integration.
  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;

    # `extensions` deliberately left unset — see the per-browser forcelist below.
    # This option feeds one shared ExtensionInstallForcelist into the managed
    # policies of chromium, google-chrome *and* brave, which is the wrong shape
    # here: the two installed browsers want different content blocking.
  };
  nixpkgs.config.chromium.enableWideVine = true;

  # Content blocking, per browser rather than per policy-module.
  #
  # Chromium gets uBlock Origin **Lite** (MV3). The MV2 uBlock Origin ID
  # cjpalhdlnbpafiamejdnhcphjbkeiagm used to be forced here and cannot work any
  # more: it is delisted from the Chrome Web Store, so the forcelist has nothing
  # to fetch, and Chromium has wound MV2 down regardless. A forcelist entry that
  # cannot resolve fails quietly — the browser simply has no blocker.
  #
  # Brave is left alone on purpose. Shields is built in and on by default, and
  # stacking a second blocker on top of it is what Brave itself advises against.
  #
  # Written straight to Chromium's own policy directory instead of through
  # programs.chromium.extensions, because that option cannot target one browser:
  # Chromium merges every *.json under /etc/chromium/policies/managed/, and
  # nothing under it reaches /etc/brave/.
  environment.etc."chromium/policies/managed/content-blocking.json".text = builtins.toJSON {
    # uBlock Origin Lite. No update URL: a bare ID means the Chrome Web Store.
    ExtensionInstallForcelist = ["ddkjiahejlhfcafbddmgiahcphecmpfh"];
  };

  # Native Wayland for the Chromium family — and for every other nixpkgs
  # Electron app on the system, not just the browsers here.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # plasma-browser-integration is deliberately absent: plasma6 already ships it
  # (its optionalPackages) on every host that imports this module, and the
  # package alone does nothing — the wiring above is what registers the host.
  environment.systemPackages = with pkgs; [
    brave
    chromium
  ];

  # google-chrome dropped. To run it once without installing it, unfree has to
  # be allowed for that eval explicitly — the system's allowUnfree does not
  # carry into `nix run`:
  #   NIXPKGS_ALLOW_UNFREE=1 nix run --impure nixpkgs#google-chrome
}
