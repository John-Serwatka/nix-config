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
  #
  # No `rebuild` alias either, for the same reason. It used to be
  # `sudo nixos-rebuild switch --flake ~/nix-config`, which assumed a clone at a
  # fixed path that only exists for withrin on the desktop and laptop — not for
  # booth-admin, and not on the kiosks, which are deployed to rather than built
  # on. `just rebuild` is the real entrypoint: it runs from the repo it is in and
  # names the host explicitly.
}
