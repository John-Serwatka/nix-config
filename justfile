# justfile — developer entry point for this NixOS flake.
#
# Run `just` (no args) or `just --list` to see every recipe, grouped by area.
# Recipes wrap the underlying Nix commands so common workflows are short,
# consistent, and discoverable across machines.
#
# Conventions for growing this file:
#   * one recipe = one workflow; prefer wrapping existing commands over logic
#   * give every recipe a `#` doc comment — it shows up in `just --list`
#   * tag recipes with [group('...')] so `just --list` stays organized
#   * grow it under the section banners below (SOPS, Home Manager, VM, deploy)

# Target host for nixos-rebuild, detected automatically so the same recipe
# works on desktop, laptop, etc. without editing the command.
hostname := `hostname`

# Show all available recipes (runs when `just` is called with no arguments).
default:
    @just --list

# ─── Core ─────────────────────────────────────────────────────────────────────

# Format every Nix file with the flake's formatter (alejandra).
[group('core')]
fmt:
    nix fmt

# Evaluate the flake and every host configuration.
[group('core')]
check:
    nix flake check

# Format, then check — run before committing.
[group('core')]
verify: fmt check

# ─── System ───────────────────────────────────────────────────────────────────

# Build this host's configuration without activating it.
[group('system')]
build:
    sudo nixos-rebuild build --flake .#{{ hostname }}

# Build, activate, and set as the boot default for this host.
[group('system')]
rebuild:
    sudo nixos-rebuild switch --flake .#{{ hostname }}

# Build and activate for this boot only (not made the boot default).
[group('system')]
test:
    sudo nixos-rebuild test --flake .#{{ hostname }}

# Roll back to the previous generation and activate it.
[group('system')]
rollback:
    sudo nixos-rebuild switch --rollback

# Activate a specific past generation by number (see `just generations`).
[group('system')]
rollback-to gen:
    sudo nix-env -p /nix/var/nix/profiles/system --switch-generation {{ gen }} && \
        sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

# ─── Maintenance ──────────────────────────────────────────────────────────────

# Update all flake inputs (nixpkgs, home-manager, sops-nix, ...).
[group('maintenance')]
update:
    nix flake update

# Update a single flake input (e.g. `just update-input nixpkgs`).
[group('maintenance')]
update-input input:
    nix flake update {{ input }}

# Note: reverts the lockfile only (pair with `just rollback` for the running
# system); if the update was already committed, use `git revert` instead.
# Undo an *uncommitted* flake update — restore flake.lock from git.
[group('maintenance')]
update-revert:
    git restore --staged --worktree --source=HEAD flake.lock

# Collect garbage: remove generations older than `age` (default 14d).
[group('maintenance')]
gc age="14d":
    sudo nix-collect-garbage --delete-older-than {{ age }}

# List this host's system generations.
[group('maintenance')]
generations:
    nixos-rebuild list-generations

# ─── Secrets (SOPS) ───────────────────────────────────────────────────────────
# TODO: edit (sops secrets/secrets.yaml), rekey (sops updatekeys),
#       add-recipient. See modules/core/sops.nix.

# ─── Home Manager ─────────────────────────────────────────────────────────────
# TODO: standalone Home Manager recipes, if ever used outside nixos-rebuild.

# ─── VM testing ───────────────────────────────────────────────────────────────
# TODO: build + run a throwaway VM of a host (nixos-rebuild build-vm).

# ─── Deployment ───────────────────────────────────────────────────────────────
# TODO: remote deploy (nixos-rebuild --target-host / deploy-rs).
