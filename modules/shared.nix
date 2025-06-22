# modules/shared.nix — System-wide settings shared by all hosts

{ config, pkgs, ... }:

{
  # No imports here—keep hardware-configuration in each host

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  networking.networkmanager.enable = true;

  # Printing, sound, etc.
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Allow Flatpak applications, e.g. for Spotify installation
  services.flatpak.enable = true;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Input
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Udev rules
  services.udev.packages = [ pkgs.ckb-next pkgs.libratbag ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Minimal system packages—root/system recovery tools only
  environment.systemPackages = with pkgs; [
    vim
    nano
  ];

  # User definition (minus packages—handled by Home Manager)
  users.users.withrin = {
    isNormalUser = true;
    description = "John Serwatka";
    extraGroups = [ "networkmanager" "wheel" "input" ];
  };

  # system.stateVersion is set per-host
}
