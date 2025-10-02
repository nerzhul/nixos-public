{config, lib, pkgs, ... }:
let
  # Must be synced with kernel.nix
  nix_rpi5_pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/3ecacf46f1924b866212611642480271610c2825.tar.gz") {};
  linux_rpi5 = pkgs.callPackage ./kernel.nix {
    kernelPatches = with pkgs.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    ignoreConfigErrors = true;
  };

  linuxPackages_rpi5 = pkgs.linuxPackagesFor linux_rpi5;
in {
  boot.kernelPackages = linuxPackages_rpi5;
  environment.systemPackages = with nix_rpi5_pkgs; [
    raspberrypifw
    raspberrypiWirelessFirmware
    raspberrypi-eeprom
  ];
}