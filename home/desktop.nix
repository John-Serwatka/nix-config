{ config, pkgs, ... }:

{
  # Import the shared config for all hosts
  imports = [ ./home.nix ];

  # Add desktop-only user packages
  home.packages = with pkgs; [
    ckb-next
    piper
    libratbag
    # ...any other desktop-only user apps...
  ] ++ (config.home.packages or []);

  # You can also override/extend other user-level options here if needed
}
