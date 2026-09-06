# modules/programs/obs.nix — OBS Studio with the virtual camera wired up
#
# Deliberately host-side rather than a Home Manager profile, unlike the rest of
# the media stack. The virtual camera is a kernel module (v4l2loopback), and
# programs.obs-studio.enableVirtualCamera is what sets boot.kernelModules and
# boot.extraModulePackages for it — a user profile cannot load kernel modules,
# so OBS installed from home.packages can never offer "Start Virtual Camera".
#
# Plugins, if any are ever needed, go in programs.obs-studio.plugins; the module
# wraps OBS with them (pkgs.wrapOBS) so they are found without OBS_PLUGINS_PATH.
{...}: {
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };
}
