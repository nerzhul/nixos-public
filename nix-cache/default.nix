{ config, pkgs, lib, ... }:
with lib; {
  config = {
    # Active nix-serve et sa clé privée
    services.nix-serve.enable = true;
    services.nix-serve.secretKeyFile = "/var/cache-priv-key.pem";
  };
}
