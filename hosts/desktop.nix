{ config, pkgs, ... }: {
  # Only settings or packages unique to desktop go here!
  home.packages = with pkgs; [
    ckb-next
    piper
    libratbag
    # Add more desktop-only stuff
  ];
}
