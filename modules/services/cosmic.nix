# modules/services/cosmic.nix — COSMIC as the default session, Plasma kept
{...}: {
  # Keep SDDM and Plasma owned by desktop.nix. Enabling only the desktop
  # environment adds COSMIC to SDDM's session chooser without replacing the
  # display manager; Plasma stays selectable there as a fallback.
  services.desktopManager.cosmic = {
    enable = true;
    xwayland.enable = true;
  };

  # plasma6 sets this with mkDefault; a plain assignment outranks it.
  # "cosmic" is the name of cosmic-session's wayland-sessions/cosmic.desktop.
  services.displayManager.defaultSession = "cosmic";
}
