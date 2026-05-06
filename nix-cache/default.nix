{
  config,
  pkgs,
  lib,
  ...
}:
let
  atticdCfg = config.services.atticd-secret;
in
with lib;
{
  imports = [
    "${
      builtins.fetchGit {
        url = "https://github.com/zhaofengli/attic.git";
        ref = "main";
      }
    }/nixos/atticd.nix"
  ];

  options = {
    services.atticd-secret = {
      content = mkOption {
        default = "";
        type = types.str;
        description = "The base64-encoded secret for generating JWTs for Atticd.";
      };
    };
  };

  config = {
    services.atticd = {
      enable = true;

      # Replace with absolute path to your environment file
      environmentFile = "/etc/atticd.env";

      settings = {
        listen = "[::]:8087";

        jwt = { };

        # Data chunking
        #
        # Warning: If you change any of the values here, it will be
        # difficult to reuse existing chunks for newly-uploaded NARs
        # since the cutpoints will be different. As a result, the
        # deduplication ratio will suffer for a while after the change.
        chunking = {
          # The minimum NAR size to trigger chunking
          #
          # If 0, chunking is disabled entirely for newly-uploaded NARs.
          # If 1, all NARs are chunked.
          nar-size-threshold = 64 * 1024; # 64 KiB

          # The preferred minimum size of a chunk, in bytes
          min-size = 16 * 1024; # 16 KiB

          # The preferred average size of a chunk, in bytes
          avg-size = 64 * 1024; # 64 KiB

          # The preferred maximum size of a chunk, in bytes
          max-size = 256 * 1024; # 256 KiB
        };
      };
    };

    environment.etc."atticd.env".text = ''
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="${atticdCfg.content}"
    '';
  };
}
