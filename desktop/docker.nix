{ config, pkgs, ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";
  users.extraGroups.docker.members = [ "nrz" ];
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}

