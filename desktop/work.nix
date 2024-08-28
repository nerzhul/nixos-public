{ config, pkgs, lib, ... }:
let
    workCfg = config.desktop.work;
in
with lib;
{
  options = {
    desktop.work = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Enable work config.'';
      };
    };
  };
  config = mkIf workCfg.enable {
    services.udev.packages = [ pkgs.yubikey-personalization ];
    environment.systemPackages = with pkgs; [
      mkosi
      kustomize
      python312Packages.ansible-core
      qemu
      qemu_kvm
      opensc
      ccid
      tailscale
      yq
      yubikey-personalization-gui
    ];
  };
}
