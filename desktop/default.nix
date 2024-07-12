{ config, pkgs, ... }:
{
  imports = [
    ./users.nix
    ./desktopEnv.nix
    ./keyring.nix
  ];

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    curl
    git
    docker
  ];

  programs.direnv.enable = true;
  system.copySystemConfiguration = true;
}

