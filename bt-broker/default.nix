{ config, pkgs, ... }:
let
  firmwareRtl8761bu = (pkgs.runCommand "rtl8761bu-firmware" {
  } ''
    mkdir -p $out/lib/firmware/rtl_bt
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8761bu_fw.bin \
         $out/lib/firmware/rtl_bt/rtl8761bu_fw.bin
  '');
in
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
        General = {
        Experimental = true; # Show battery charge of Bluetooth devices
        };
    };
  };

  security.rtkit.enable = true; # Real-time scheduling for audio
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    extraConfig.pipewire."bluez-monitor" = {
      properties = {
        "bluez5.enable" = true;
        "bluez5.roles" = [ "a2dp_sink" "a2dp_source" "headset_head_unit" "headset_audio_gateway" ];
      };
    };
  };

  hardware.pulseaudio.enable = false;

  nixpkgs.config.pipewire = {
    withBluetooth = true;
    withAlsa = true;
  };

  system.activationScripts.customFirmware.text = ''
    mkdir -p /lib/firmware/rtl_bt
    cp -r ${firmwareRtl8761bu}/lib/firmware/rtl_bt/* /lib/firmware/rtl_bt/
  '';

  nixpkgs.config.allowUnfree = true;
}