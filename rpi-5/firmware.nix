{ config, pkgs, lib, ... }:

let
  firmwareRev = "89752d47a688ec33c9f0c38f6549f627e5c143f9";

  rpiFirmware = pkgs.stdenvNoCC.mkDerivation {
    pname = "rpi5-firmware";
    version = firmwareRev;

    src = pkgs.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "firmware";
      rev = firmwareRev;
      hash = "sha256-xYvLFMBGTrW1730YRJXGLJWFJ7r570MA63McKnqWtF4=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # Layout standard Debian/Raspbian: /usr/share/raspberrypi/firmware/boot/*
      mkdir -p $out/share/raspberrypi/firmware
      cp -r boot $out/share/raspberrypi/firmware/boot

      runHook postInstall
    '';

    meta = with lib; {
      description = "Raspberry Pi 5 firmware blobs + DTBs (commit ${firmwareRev})";
      license = licenses.unfreeRedistributableFirmware;
      platforms = [ "aarch64-linux" ];
    };
  };
in
{
  system.extraDependencies = [ rpiFirmware ];

  environment.systemPackages = [ rpiFirmware ];

  boot.kernelModules = [ "bcm2835_wdt" ];
}
