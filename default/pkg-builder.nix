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

  # To generate keys for nix-builder cache:
  # sudo mkdir -p /etc/nix/keys
  # sudo nix key generate-secret --key-name mycache > /etc/nix/keys/mycache-priv.pem
  # sudo nix key convert-secret-to-public /etc/nix/keys/mycache-priv.pem > /etc/nix/keys/mycache-pub.pem

  config = mkIf config.nixBuilder {
    nix.settings.secret-key-files = [ "/etc/nix/keys/mycache-priv.pem" ];
  };
}
