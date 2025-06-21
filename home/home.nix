# home/home.nix — Shared user config for all hosts

{ config, pkgs, ... }:

{
  home.username = "withrin";
  home.homeDirectory = "/home/withrin";
  home.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;

  programs.git = {
    enable = true;
    userName = "withriin";
    userEmail = "johnchrisserwatka@gmail.com";
  };

  programs.zsh.enable = true;
  programs.bash.enable = true;

  home.packages = with pkgs; [
    kdePackages.kate
    brave
    spotify
    discord
    neovim
    git
    wget
    prismlauncher
    # Add more common packages here!
  ];

  # You can add more shared config here, like dotfiles, aliases, shell theme, etc.
}
