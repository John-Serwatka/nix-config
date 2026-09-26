# modules/services/sunshine.nix — Sunshine game-stream host for Moonlight
#
# The stock NixOS module runs Sunshine as a *user* service wantedBy
# graphical-session.target. COSMIC's cosmic-session.target BindsTo that target
# (as Plasma's session does), so Sunshine starts with any normal graphical
# login and stops with it. Moonlight connects straight to it; nothing else is
# involved.
#
# No prep-cmd anywhere: a stream must never change resolution, monitor layout
# or anything else about the local session. The only app is "Desktop", which
# streams whatever is on screen.
#
# Capture is KMS, which needs CAP_SYS_ADMIN (capSysAdmin installs
# /run/wrappers/bin/sunshine with cap_sys_admin+p). It is the only unattended
# path on NVIDIA under Wayland: portal capture asks for consent interactively,
# and NvFBC is X11-only and needs a CUDA build.
#
# Encoder: Vulkan Video (h264_vulkan / hevc_vulkan), not NVENC. nixpkgs builds
# sunshine without CUDA here, and its NVENC path needs libcuda.so.1 — which
# lives in /run/opengl-driver/lib, is not in the binary's RUNPATH, and cannot be
# supplied through LD_LIBRARY_PATH because the capability wrapper makes the
# process secure-exec. So NVENC fails at startup (`Cannot load libcuda.so.1`)
# and Sunshine falls back to Vulkan, which is still GPU hardware encoding.
# Deliberately left that way until Moonlight testing shows Vulkan is not good
# enough; the first experiment then is a copy of this package with
# /run/opengl-driver/lib added to its RUNPATH (patchelf, no recompile). See
# docs/superpowers/plans/2026-09-25-game-streaming-broker.md.
#
# Firewall: deliberately not openFirewall — that writes the GLOBAL port lists
# and would expose the stream on every interface, the kiosk USB share
# included. The desktop opens the ports per interface instead
# (hosts/desktop/default.nix). The web UI (47990) is opened nowhere and only
# answers localhost (origin_web_ui_allowed = pc): pair from a browser on this
# machine at https://localhost:47990. Sunshine classifies Tailscale's
# 100.64.0.0/10 as "lan", so the default `lan` would have admitted any tailnet
# device had the port been open.
#
# Setting `settings` makes the config file authoritative: the web UI can no
# longer change configuration, only pair clients and manage credentials.
{...}: {
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = false;
    settings = {
      capture = "kms";
      origin_web_ui_allowed = "pc";
      # Already the default; stated so it cannot drift on silently.
      upnp = "disabled";
    };
    applications.apps = [{name = "Desktop";}];
  };
}
