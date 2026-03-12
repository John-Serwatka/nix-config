# modules/services/audio.nix — PipeWire audio with ALSA and PulseAudio compat
{ ... }:

{
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;  # PulseAudio socket for legacy clients
  };
  security.rtkit.enable = true;
}
