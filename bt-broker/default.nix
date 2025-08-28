{ config, pkgs, ... }:
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

  services.pipewire = {
    enable = true; # if not already enabled
  };

  nixpkgs.overlays = [
    (self: super: {
      linux-firmware-uncompressed = super.linux-firmware.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          echo "Decompressing rtl8761bu_fw.bin.zst..."
          mkdir -p $out/lib/firmware/rtl_bt
          zstd -d $out/lib/firmware/rtl_bt/rtl8761bu_fw.bin.zst \
            -o $out/lib/firmware/rtl_bt/rtl8761bu_fw.bin
        '';
      });
    })
  ];

  hardware.firmware = [ pkgs.linux-firmware-uncompressed ];

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.allowUnfree = true;
}