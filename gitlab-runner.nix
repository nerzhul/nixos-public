{ config, pkgs, lib, ... }:
with lib;

{
  imports = [ ];
  services.gitlab-runner.enable = true;
  systemd.services.gitlab-runner.serviceConfig =  let config =
      (pkgs.formats.toml{}).generate "gitlab-runner.toml" {
        concurrent = 1;
        runners = [
          {
            name = "Nix runner";
            url = "https://gitlab.com";
            id = 12354;
            token = "<toset>";
            executor = "docker";
            docker = {
              image = "debian:12";
              pull_policy = "if-not-present";
              allowed_pull_policies = ["if-not-present"];
            };
            environment = [
            ];
          }
        ];
      };
      configPath = "$HOME/.gitlab-runner/config.toml";
      configureScript = pkgs.writeShellScript "gitlab-runner-configure" ''
        mkdir -p $(dirname ${configPath})
        ${pkgs.gawk}/bin/awk '{
          for(varname in ENVIRON)
            gsub("@"varname"@", ENVIRON[varname])
          print
        }' "${config}" > "${configPath}"
        chown -R --reference=$HOME $(dirname ${configPath})
      '';
   in {
     #EnvironmentFile = "/run/secrets/gitlab-runner.env";
     ExecStartPre = mkForce "!${configureScript}";
     ExecReload = mkForce "!${configureScript}";
   };
}
