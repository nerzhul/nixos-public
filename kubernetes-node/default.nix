{ config, pkgs, ... }:
{
  imports = [
    ./containerd.nix
    ./kubelet.nix
  ]
}