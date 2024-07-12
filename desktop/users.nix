{ config, pkgs, lib, ... }:
with lib;

{
  nixpkgs.config.allowUnfree = true;

  users.users.nrz = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      firefox
      git
      keepassxc
      nextcloud-client
      starship
      gnupg
      vscode
      go
      delve # golang debugger
      gcc # for CGO
      direnv
      pkgs.gnomeExtensions.appindicator
      gcr
    ];
  };

  security.sudo.extraRules = [{
    users = [ "nrz" ];
    commands = [{
      command = "ALL";
    }];
  }];
}
