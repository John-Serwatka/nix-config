{ config, lib, ... }:

{
  ## ─── Option ──────────────────────────────────────────────────────────────
  options.hardware.cpu.amd.enablePstate = lib.mkEnableOption ''
    Enable the modern AMD P-state driver (“amd_pstate=active”) for Zen 3 / Zen 4.
  '';

  ## ─── Implementation ─────────────────────────────────────────────────────
  config = lib.mkIf config.hardware.cpu.amd.enablePstate {
    boot.kernelModules = [ "amd_pstate" ];
    boot.kernelParams  = [ "amd_pstate=active" ];
  };
}
