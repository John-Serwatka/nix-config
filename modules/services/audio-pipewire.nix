# modules/services/audio-pipewire.nix
{ config, … }:
{
  services.pipewire = {
    enable               = true;
    alsa.enable          = true;
    alsa.support32Bit    = true;
    pulse.enable         = true;  # gives you a PulseAudio socket for legacy clients
  };
}
