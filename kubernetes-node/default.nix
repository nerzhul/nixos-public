{ config, pkgs, ... }:
{
  imports = [
    ./containerd.nix
    ./kubelet.nix
  ];

  services.containerd.enable = true;
  services.kubelet.enable = true;
  services.cloud-init.enable = true;
}
