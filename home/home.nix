{ config, pkgs, ... }:

{
  home.username = "withrin";
  home.homeDirectory = "/home/withrin";
  home.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;
  programs.bash.enable = true;

  # Add more shared apps/settings here
  home.packages = with pkgs; [
    kdePackages.kate
    brave
    spotify
    discord
    neovim
    git
    wget
    prismlauncher
    # Add more common packages
  ];

  programs.git = {
    enable = true;
    userName = "withriin";
    userEmail = "johnchrisserwatka@gmail.com";
  };



    # KDE-related config (optional; KDE is usually managed system-wide but you can set dotfiles here)
  # programs.kdeconnect.enable = true;

  # Set up basic shell prompt, aliases, etc. if you want
  # programs.starship.enable = true;
  # programs.fzf.enable = true;
  # You can also import other shared modules
  # imports = [ ./another-shared-module.nix ];
}
