{ config, pkgs, ... }:
{
  imports = [
    ./containerd.nix
    ./kubelet.nix
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
  ];
}
