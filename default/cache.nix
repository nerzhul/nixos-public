{ config, pkgs, lib, ... }:
with lib; {
  options = {
    nixCacheTrustedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Public key for trusted nix cache
      '';
    };
    nixAdditionalSubstituters = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Additional nix substituters
      '';
    };
  };

  config = {
    nix.settings.trusted-public-keys =
      mkIf (config.nixCacheTrustedKeys != [ ]) config.nixCacheTrustedKeys;
    nix.settings.substituters = config.nixAdditionalSubstituters;
  };
}
