{config, lib, pkgs, ... }:
let
  linux_rpi5 = pkgs.callPackage ./kernel.nix {
    kernelPatches = with pkgs.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];
    extraConfig = ''
    '';
  };

  linuxPackages_rpi5 = pkgs.linuxPackagesFor linux_rpi5;
in {
  boot.kernelPackages = linuxPackages_rpi5;
}