{ config, pkgs, lib, ... }:
with lib;

{
  services.gnome.gnome-keyring.enable = true;
  security = {
    pam.services = {
      login = {
        # startSession = true;
        enableGnomeKeyring = true;
      };
    };
    polkit = {
      enable = true;
    };
  };

  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
