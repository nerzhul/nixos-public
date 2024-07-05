{ config, pkgs, lib, ... }:
with lib;

{
  security.sudo.extraRules = [{
    users = [ "nrz" ];
    commands = [{
      command = "ALL";
    }];
  }];
}
