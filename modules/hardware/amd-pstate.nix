# modules/hardware/amd-pstate.nix — AMD P-State CPU frequency driver (EPP mode)
#
# amd_pstate is built into the NixOS kernel, so no boot.kernelModules entry is
# needed. `active` has been the default mode for supported CPUs since ~6.3; the
# param is kept as explicit intent (and covers CPUs where the default differs).
{...}: {
  boot.kernelParams = ["amd_pstate=active"];
}
