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
    environment.systemPackages = with pkgs; [
      mkosi
      python312Packages.ansible-core
    ];
  };
}