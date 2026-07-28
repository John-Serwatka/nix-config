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
# works on any host defined in this flake, without editing the command.
hostname := `hostname`

# Local export directory for Horde of Viscount, used by `kiosk-deploy-hov`.
# Sean ships a zip (misleadingly named .appimage); `build/` is the unpacked
# tree plus the run.sh the kiosk launcher expects.
hov_dir := "/home/withrin/PocketLoreStudios/Swiggins/HoV/Kiosk/build"

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

# Format + check — the gate that should pass before committing.
[group('core')]
ci: fmt check

# Alias for `ci` — reads nicely for local pre-commit use.
[group('core')]
verify: ci

# Quick repo/system sanity check (host, branch, status, flake metadata).
[group('core')]
doctor:
    @echo "Hostname: {{ hostname }}"
    @git branch --show-current
    @git status --short
    @nix flake metadata --no-write-lock-file

# ─── System ───────────────────────────────────────────────────────────────────

# Build this host's configuration without activating it.
[group('system')]
build:
    sudo nixos-rebuild build --flake .#{{ hostname }}

# Preview what `rebuild` would change, without activating — a safe step between build and rebuild.
[group('system')]
diff:
    sudo nixos-rebuild dry-activate --flake .#{{ hostname }}

# Build, activate, and set as the boot default for this host.
[group('system')]
rebuild:
    sudo nixos-rebuild switch --flake .#{{ hostname }}

# Build and set for next boot without activating now (good for riskier changes).
[group('system')]
boot:
    sudo nixos-rebuild boot --flake .#{{ hostname }}

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

# Remove leftover build symlinks (result, result-*) from local experiments.
[group('maintenance')]
clean:
    rm -f result result-*

# ─── Secrets (SOPS) ───────────────────────────────────────────────────────────
# TODO: edit (sops secrets/secrets.yaml), rekey (sops updatekeys),
#       add-recipient. See modules/core/sops.nix.

# ─── Home Manager ─────────────────────────────────────────────────────────────
# TODO: standalone Home Manager recipes, if ever used outside nixos-rebuild.

# ─── VM testing ───────────────────────────────────────────────────────────────
# TODO: build + run a throwaway VM of a host (nixos-rebuild build-vm).

# ─── Installer image ──────────────────────────────────────────────────────────

# Build the bootable USB installer carrying this flake (see hosts/installer).
# Write it with:
#   sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
# Check the device with `lsblk` first — dd to the wrong one erases that disk.
[group('installer')]
iso:
    nix build .#installer

# ─── Deployment ───────────────────────────────────────────────────────────────
# Push this flake's *system config* to another machine over SSH. The build runs
# locally and only the closure is copied, so the kiosks never compile anything.
#
# `host` has to work as both an SSH name and a nixosConfigurations attribute in
# flake.nix — that holds for optiplex and beelink.
#
# withrin's sudo on the targets is password-protected (no NOPASSWD), so
# --ask-sudo-password prompts once per deploy; plain `--sudo` would just hang.
#
# This is the *config* half of a kiosk update — `kiosk-deploy` below ships the
# game build. A game deployed into a layout the running config doesn't know
# about sits in the launcher's retry loop forever, so when a change touches
# modules/services/kiosk.nix, run both.

# Build <host>'s config locally, copy it over, and activate it on <host>.
[group('deploy')]
deploy host:
    nixos-rebuild switch --flake .#{{ host }} \
        --target-host withrin@{{ host }} --ask-sudo-password

# Like `deploy`, but only sets it as the boot default (no activation now).
[group('deploy')]
deploy-boot host:
    nixos-rebuild boot --flake .#{{ host }} \
        --target-host withrin@{{ host }} --ask-sudo-password

# Build another host's config locally, without touching that machine.
[group('deploy')]
deploy-build host:
    nixos-rebuild build --flake .#{{ host }}

# ─── Kiosk game deploys ───────────────────────────────────────────────────────
# Game builds ship independently of NixOS (see modules/services/kiosk.nix):
# rsync an export into its own directory under /opt/kiosk on the kiosk host,
# then flip the `current` symlink at it. `host` is an SSH-reachable name (e.g.
# optiplex, beelink); `game` names the directory under /opt/kiosk; `dir` is
# the local exported build (must contain an executable run.sh).

# Sync an exported build to <host>:/opt/kiosk/<game>/ and flip `current` at it.
[group('kiosk')]
kiosk-deploy dir game host:
    #!/usr/bin/env bash
    set -euo pipefail
    chmod +x "{{ dir }}/run.sh"
    # Engine entrypoints are named differently per engine (Godot ships
    # <Name>.x86_64, GameMaker ships `tester`), so mark every top-level ELF
    # executable by magic bytes rather than matching a filename glob — the
    # old `*.x86_64` glob hard-failed on builds that had no such file.
    for f in "{{ dir }}"/*; do
      [ -f "$f" ] || continue
      if head -c4 "$f" | od -An -tx1 | tr -d ' \n' | grep -q '^7f454c46'; then
        chmod +x "$f"
      fi
    done
    # Content hash of the whole tree, so two deploys that share a directory name
    # can still be told apart (a new build of the same game keeps its name).
    build_id=$(find "{{ dir }}" -type f -print0 | sort -z | xargs -0 sha256sum \
      | sha256sum | cut -c1-16)

    ssh withrin@{{ host }} 'mkdir -p /opt/kiosk/{{ game }}'
    rsync -av --delete "{{ dir }}/" withrin@{{ host }}:/opt/kiosk/{{ game }}/

    # Provenance for `kiosk-status`. Written after the rsync, because --delete
    # would otherwise remove it on the next deploy before it could be rewritten.
    printf 'source:   %s\nbuild-id: %s\ndeployed: %s\nby:       %s\n' \
      "{{ dir }}" "$build_id" "$(date -Is)" "$USER@$(hostname)" \
      | ssh withrin@{{ host }} 'cat > /opt/kiosk/{{ game }}/.deploy-info'

    ssh withrin@{{ host }} 'ln -sfn {{ game }} /opt/kiosk/current'

# Deploy Horde of Viscount from its export directory (see hov_dir at the top).
[group('kiosk')]
kiosk-deploy-hov host:
    just kiosk-deploy {{ hov_dir }} HordeOfViscount {{ host }}

# Show which build is live on a kiosk, and what else is sitting in /opt/kiosk.
[group('kiosk')]
kiosk-status host:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh withrin@{{ host }} 'bash -s' <<'REMOTE'
    cur=$(readlink /opt/kiosk/current 2>/dev/null || echo "")
    echo "live: ${cur:-(nothing deployed)}"
    for d in /opt/kiosk/*/; do
      [ -d "$d" ] || continue
      # `current` matches this glob too (symlink to a directory) — skip it so it
      # is not reported as a build of its own.
      [ -L "${d%/}" ] && continue
      n=$(basename "$d")
      if [ "$n" = "$cur" ]; then echo; echo "* $n   <- current"; else echo; echo "  $n"; fi
      [ -f "$d/VERSION" ] && echo "    version:  $(cat "$d/VERSION")"
      if [ -f "$d/.deploy-info" ]; then
        sed 's/^/    /' "$d/.deploy-info"
      else
        echo "    (no .deploy-info — predates provenance tracking)"
      fi
      echo "    entrypoint: $(ls -l "$d/run.sh" 2>/dev/null | awk '{print $5" bytes  "$6" "$7" "$8}')"
    done
    REMOTE

# The launcher loop survives this: it sees the game exit and starts it again
# after 2s, so a freshly rsynced build comes up without a reboot. Matches on the
# entrypoint path rather than a process name, so it works whatever the engine
# calls its binary. `-t` because the game runs as the kiosk user, and withrin's
# sudo needs a password.

# Relaunch the game to pick up a freshly deployed build, without rebooting.
[group('kiosk')]
kiosk-restart host:
    ssh -t withrin@{{ host }} 'sudo pkill -u kiosk -f /opt/kiosk/current/run.sh'

# Reboot a kiosk host to pick up a freshly deployed build.
[group('kiosk')]
kiosk-reboot host:
    ssh withrin@{{ host }} sudo reboot

# Tail the kiosk launcher's logs on a host.
[group('kiosk')]
kiosk-logs host:
    ssh withrin@{{ host }} 'journalctl -t kiosk -b -f'
