{ config, pkgs, ... }:
let
  firmwareRtl8761bu = (pkgs.runCommand "rtl8761bu-firmware" { } ''
    mkdir -p $out/lib/firmware/rtl_bt
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8761bu_fw.bin \
         $out/lib/firmware/rtl_bt/rtl8761bu_fw.bin
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8761bu_config.bin \
         $out/lib/firmware/rtl_bt/rtl8761bu_config.bin
  '');

  isAarch64 = builtins.match "aarch64-.*" builtins.currentSystem != null;
  rpi5LinuxPackage = (import (builtins.fetchTarball
    "https://gitlab.com/vriska/nix-rpi5/-/archive/main.tar.gz")).legacyPackages.aarch64-linux.linuxPackages_rpi5;
  brokerName = "BrokerBroken";
  audioUserID = 1001;
in {
  imports = [ ./broker-app.nix ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = { General = { Class = "0x20041C"; }; };
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
      extraConfig = {
        "99-bluetooth" = {
          "wireplumber.profiles" = {
            "main" = { "monitor.bluez.seat-monitoring" = "disabled"; };
          };
        };
      };
    };

    extraConfig.client = {
      "combined-sink" = {
        "context.modules" = [{
          "name" = "libpipewire-module-combine-stream";
          "args" = {
            "node.description" = "Combined Output";
            "node.name" = "combined_output";
            "combine.mode" = "sink";
            "combine.props" = {
              "audio.position" = [ "FL" "FR" ];
            };
            "stream.props" = { };
            "stream.rules" = [
              {
                "matches" = [
                  {
                    "media.class" = "Audio/Sink";
                    # Match all bluetooth output devices
                    "node.name" = "~bluez_output.*";
                  }
                ];
                "actions" = {
                  "create-stream" = {
                  };
                };
              }
            ];
          };
        }];
      };
    };
  };

  users.extraUsers.audio-broker = {
    enable = true;
    group = "audio";
    extraGroups = [ "audio" "pipewire" "video" "wheel" ];
    isNormalUser = true;
    linger = true;
    uid = audioUserID;
    description = "Audio Broker User";

    # Remember you need (currently) some manual config in the user context
    # export XDG_RUNTIME_DIR=/run/user/$(id -u)
    # systemctl --user enable pipewire pipewire-pulse wireplumber
    # systemctl --user start pipewire pipewire-pulse wireplumber
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
