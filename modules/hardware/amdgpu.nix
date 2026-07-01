{
  config,
  pkgs,
  ...
}: {
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # Note: this module intentionally does not set services.xserver.videoDrivers.
  # Because videoDrivers is a list, per-host assignments concatenate rather than
  # override, so the driver list is declared once per host (see hosts/*/default.nix).
}
