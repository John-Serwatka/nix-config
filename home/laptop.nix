{ config, pkgs, ... }:

{
  imports = [ ./home.nix ];  # Import all shared user config

  # Add any laptop-specific user packages here.
  # This will merge with the shared packages.
  home.packages = with pkgs; [
    # Example: Keep this blank if no laptop-only packages
    # or add something like:
    # keepassxc
    # networkmanagerapplet
  ] ++ (config.home.packages or []);

  # You can override or extend any other Home Manager option here.
  # For example, to use a different shell or theme on laptop only:
  # programs.zsh.enable = false;
  # programs.bash.enable = true;

  # Add any more laptop-specific user config here!
}
