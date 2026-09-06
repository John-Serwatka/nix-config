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

  # No EDITOR here on purpose. This profile is imported by every user on every
  # host, including booth-admin, which has no editor of its own — announcing
  # `nvim` from here pointed that account at a binary it never installed.
  # Whichever profile installs the editor owns EDITOR (see programs.neovim.
  # defaultEditor in profiles/home/dev.nix and users/withrin/home-kiosk.nix).
}
