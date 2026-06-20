# modules/programs/communication.nix — chat and messaging apps
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # discord
    vesktop
  ];
}
