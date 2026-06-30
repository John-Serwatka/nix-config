# profiles/home/git.nix — shared git configuration (user-owned, opt-in)
#
# Aliases, delta diffs, and sane defaults. Per-user identity (user.name /
# user.email) stays in the user's own home.nix, since it differs per person.
{...}: {
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        lg = "log --oneline --graph --decorate";
      };
    };
  };

  # syntax-highlighted diffs, wired into git as the pager
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
