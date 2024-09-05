{ config, pkgs, ... }:
{
  imports = [
    ./containerd.nix
	./kubernetes.nix
    ./kubelet.nix
	./kube_controller_manager.nix
    ./kube_scheduler.nix
  ];

  services.containerd.enable = true;
  services.kubelet.enable = true;
  services.cloud-init.enable = true;

  services.cloud-init.settings.cloud_init_modules = [
    "migrator"
    "seed_random"
    "bootcmd"
    "write-files"
    "growpart"
    "resizefs"
    "update_hostname"
    "resolv_conf"
    "ca-certs"
    "users-groups"
    "disable_ec2_metadata"
  ];
}
