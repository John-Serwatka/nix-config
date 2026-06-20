{
  config,
  pkgs,
  ...
}: {
  # install the input stack system-wide
  environment.systemPackages = with pkgs; [
    #ckb-next
    piper
    libratbag
  ];

  # enable the device daemon for all users
  services.ratbagd.enable = true;
}
