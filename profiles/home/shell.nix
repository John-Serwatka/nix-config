# profiles/home/shell.nix — interactive shell setup (user-owned, opt-in)
#
# bash + starship prompt + aliases + direnv. Import from a user's home.nix:
#   imports = [ ../../profiles/home/shell.nix ];
{...}: {
  programs.bash = {
    enable = true;
    historyControl = ["ignoredups" "ignorespace"];
    shellAliases = {
      ll = "ls -alh";
      la = "ls -A";
      ".." = "cd ..";
      "..." = "cd ../..";

      gs = "git status";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate";

      # Rebuild this flake for the current host.
      rebuild = "sudo nixos-rebuild switch --flake ~/nix-config";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 1000;
    };
  };

  # Per-directory environments; nix-direnv caches `nix develop` shells.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim"; # provided by profiles/home/dev.nix; override per user if needed
  };
}
