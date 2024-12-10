{ config, pkgs, lib, ... }:
let
  kine-uid = 995;
  kine-gid = 995;
  kineCfg = config.services.kine;
in
with lib;
{
  options = {
    services.kine = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Enable kine daemon.'';
      };
    };
  };

  config = mkIf kineCfg.enable {
    users.extraGroups.kine.gid = kine-gid;
    users.extraUsers.kine = {
      uid = kine;
      isNormalUser = true;
      group = "kine";
    };

    systemd.services.kine = {
      enable = true;
      description = "kine (kine is not etcd)";
      wantedBy = [ "multi-user.target" ];
      documentation = [ "https://github.com/k3s-io/kine" ];
      after = [ "network.target" ];
      path = [ pkgs.kine ];

      serviceConfig = {
        User = "kine";
        Group = "kine";
        ExecStart = "${pkgs.kine}/bin/kine";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
