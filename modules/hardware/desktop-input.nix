{pkgs, ...}: {
  # install the input stack system-wide
  environment.systemPackages = with pkgs; [
    #ckb-next
    piper # GUI; libratbag itself comes from services.ratbagd below
  ];

  # enable the device daemon for all users
  services.ratbagd.enable = true;
}
