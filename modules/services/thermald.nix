# modules/services/thermald.nix — Intel thermal daemon (Intel CPUs only)
{...}: {
  services.thermald.enable = true;
}
