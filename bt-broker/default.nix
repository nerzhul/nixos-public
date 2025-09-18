{ config, pkgs, ... }:
let
  firmwareRtl8761bu = (pkgs.runCommand "rtl8761bu-firmware" {
  } ''
    mkdir -p $out/lib/firmware/rtl_bt
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8761bu_fw.bin \
         $out/lib/firmware/rtl_bt/rtl8761bu_fw.bin
  '');
  brokerName = "BrokerBroken";
in
{
  imports = [
    ./broker-app.nix
  ];
  
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
        General = {
          Class = "0x20041C";
        };
    };
  };

  security.rtkit.enable = true; # Real-time scheduling for audio
  services.pipewire = {
    enable = true;
    socketActivation = false;
    alsa.enable = true;
    alsa.support32Bit = true;
    audio.enable = true;
    pulse.enable = true;
    jack.enable = false;
    wireplumber = {
      enable = true;
    };
  };

  users.extraUsers.audio-broker = {
    enable = true;
    group = "audio";
    extraGroups = [ "audio" "pipewire" "video" "wheel" ];
    isNormalUser = true;
    linger = true;

    # Remember you need (currently) some manual config in the user context
    # export XDG_RUNTIME_DIR=/run/user/$(id -u)
    # export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
    # systemctl --user daemon-reexec
    # systemctl --user start pipewire pipewire-pulse
    # mkdir -p /home/audio-broker/.config/environment.d
    # echo "XDG_RUNTIME_DIR=/run/user/$(id -u)" > /home/audio-broker/.config/environment.d/90-runtime.conf
    # echo "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus" >> /home/audio-broker/.config/environment.d/90-runtime.conf
  };

  systemd.user.services.bluetooth-rename = {
    description = "Rename Bluetooth adapter";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bluez}/bin/bluetoothctl system-alias ${brokerName}";
    };
  };

  services.pulseaudio.enable = false;
  services.dbus.enable = true;

  system.activationScripts.customFirmware.text = ''
    mkdir -p /lib/firmware/rtl_bt
    cp -r ${firmwareRtl8761bu}/lib/firmware/rtl_bt/* /lib/firmware/rtl_bt/
  '';

  nixpkgs.config.allowUnfree = true;
}