{ config, pkgs, ... }:
{
  imports = [
    ./containerd.nix
    ./kubernetes.nix
    ./kubelet.nix
    ./kube_apiserver.nix
    ./kube_controller_manager.nix
    ./kube_scheduler.nix
    ./kine.nix
  ];

  services.containerd.enable = true;
  services.kubelet.enable = true;
}
