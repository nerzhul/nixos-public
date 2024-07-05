{ config, pkgs, ... }:
{
  imports = [
    ./users.nix
    ./desktopEnv.nix
    ./keyring.nix
  ];
}

