{ config, pkgs, ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}

