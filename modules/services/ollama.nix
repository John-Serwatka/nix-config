# modules/services/ollama.nix — local AI model server (Ollama)
#
# Host-side "local AI tooling" lives here; AI coding CLIs (claude-code, …) are
# user tooling and belong to profiles/home/dev.nix instead.
#
# NOTE: uses the CUDA build, so only import this on hosts with an NVIDIA GPU
# (currently the desktop). Split the package choice out per-host if an AMD/CPU
# host ever needs Ollama (pkgs.ollama-rocm / pkgs.ollama).
{pkgs, ...}: {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    loadModels = [
      "qwen2.5-coder:7b"
      "qwen2.5-coder:1.5b"
    ];
  };
}
