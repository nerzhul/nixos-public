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

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
}