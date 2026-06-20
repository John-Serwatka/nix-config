{config, ...}: {
  boot.kernelModules = ["amd_pstate"];
  boot.kernelParams = ["amd_pstate=active"];
}
