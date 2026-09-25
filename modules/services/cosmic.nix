# modules/services/cosmic.nix — optional COSMIC session alongside Plasma
{...}: {
  # Keep SDDM and Plasma owned by desktop.nix. Enabling only the desktop
  # environment adds COSMIC to SDDM's session chooser without replacing the
  # display manager or changing the default session.
  services.desktopManager.cosmic = {
    enable = true;
    xwayland.enable = true;
  };
}
