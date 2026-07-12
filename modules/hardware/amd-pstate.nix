# modules/hardware/amd-pstate.nix — AMD P-State CPU frequency driver (EPP mode)
#
# amd_pstate is built into the NixOS kernel, so no boot.kernelModules entry is
# needed. `active` has been the default mode for supported CPUs since ~6.3; the
# param is kept as explicit intent (and covers CPUs where the default differs).
{lib, ...}: {
  boot.kernelParams = ["amd_pstate=active"];

  # With amd-pstate-epp, "powersave" still boosts to full clocks under load
  # (the EPP bias governs that); it just lets the CPU idle low instead of
  # pinning the bias to maximum like "performance" does.
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
