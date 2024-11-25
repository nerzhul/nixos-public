{ config, pkgs, ... }:
{
  imports = [
    ./users.nix
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
}
