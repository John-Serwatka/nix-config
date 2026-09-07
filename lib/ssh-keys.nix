# lib/ssh-keys.nix — the workstation SSH public keys this flake authorizes
#
# Plain data, imported with `import ../lib/ssh-keys.nix` (no arguments). These
# are public keys: safe to commit, safe to read from the world-readable Nix
# store.
#
# Factored out because three places need the same list — a kiosk's `withrin`
# account, a kiosk's *bootstrap* root account, and the installer ISO's root
# account (hosts/installer/default.nix). Rotating a workstation key is one edit
# here instead of three, and the copies cannot drift apart.
{
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINx1ujbVZk2s/RRjVfqLOyNS4HfV1vTNLLivpFIqP0YI withrin@desktop";
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1Dul40V/Z3WrED3DXnZY9TDhIWMu0HQz/7n/fsH/0u withrin@laptop";
}
