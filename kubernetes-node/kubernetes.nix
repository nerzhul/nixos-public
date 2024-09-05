{ config, pkgs, lib, ... }:
let
  kubernetesCfg = config.services.kubernetes;
in
with lib;
{
  options = {
    services.kubernetes = {
      apiCACert = mkOption {
        default = "";
        type = types.str;
        description = ''API server CA certificate.'';
      };
	  apiCAKey = mkOption {
        default = "";
        type = types.str;
        description = ''API server CA private key.'';
      };
	};
  };
  config = {
    environment.etc."kubernetes/pki/ca.crt".text = kubernetesCfg.apiCACert;
	environment.etc."kubernetes/pki/ca.key".text = kubernetesCfg.apiCAKey;
  };
}