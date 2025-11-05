{ config, lib, ... }:

with lib;

{
  options.nixBuilder = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Setup this machine as a Nix package builder
    '';
  };

  config = mkIf config.nixBuilder {
    nix.settings.secret-key-files = [
      "/etc/nix/keys/mycache-priv.pem"
    ];
  };
}