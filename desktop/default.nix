{ config, pkgs, ... }:
{
  imports = [
    ./users.nix
    ./desktopEnv.nix
  ];
}

