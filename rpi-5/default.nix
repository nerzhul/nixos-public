{config, lib, pkgs, ... }:
let
  # Must be synced with kernel.nix
  nix_rpi5_pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/054533f5c84884e3186a722c07cbb4a6c1a2af19.tar.gz") {};
  linux_rpi5 = nix_rpi5_pkgs.callPackage ./kernel.nix {
    kernelPatches = with nix_rpi5_pkgs.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    ignoreConfigErrors = true;
  };

  linuxPackages_rpi5 = nix_rpi5_pkgs.linuxPackagesFor linux_rpi5;
in {
  boot.kernelPackages = linuxPackages_rpi5;
  environment.systemPackages = with nix_rpi5_pkgs; [
    raspberrypifw
    raspberrypiWirelessFirmware
    raspberrypi-eeprom
  ];
}