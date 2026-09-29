# modules/programs/obs.nix — OBS Studio with the virtual camera wired up
#
# Deliberately host-side rather than a Home Manager profile, unlike the rest of
# the media stack. The virtual camera is a kernel module (v4l2loopback), and
# programs.obs-studio.enableVirtualCamera is what sets boot.kernelModules and
# boot.extraModulePackages for it — a user profile cannot load kernel modules,
# so OBS installed from home.packages can never offer "Start Virtual Camera".
#
# Plugins go in programs.obs-studio.plugins; the module wraps OBS with them
# (pkgs.wrapOBS) so they are found without OBS_PLUGINS_PATH. wrapOBS also
# symlinks each plugin into the system profile, which is how obs-vkcapture's
# Vulkan layer (share/vulkan/implicit_layer.d) and its obs-gamecapture launcher
# reach games. The layer is opt-in per game: Steam launch options
# `obs-gamecapture %command%`, then add a "Game Capture" source in OBS. This
# replaces PipeWire screen capture for games, which freezes.
{pkgs, ...}: {
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = [pkgs.obs-studio-plugins.obs-vkcapture];
  };
}
