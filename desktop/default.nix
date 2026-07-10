{ config, pkgs, ... }:
{
  imports = [
    ./users.nix
    ./desktopEnv.nix
    ./keyring.nix
    ./docker.nix
    ./work.nix
  ];

  environment.systemPackages = with pkgs; [
    vim
    curl
    git
    libreoffice
  ];

  programs.direnv.enable = true;
  system.copySystemConfiguration = true;
}

