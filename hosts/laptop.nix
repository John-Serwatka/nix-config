{ config, pkgs, ... }: {
  # Only settings or packages unique to laptop go here!
  home.packages = with pkgs; [
    # Add laptop-only stuff
  ];
}
