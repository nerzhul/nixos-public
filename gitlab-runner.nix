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
            token = "glrt-PMzRpEHznRa7qUPrNnJW";
            executor = "docker";
            docker = {
              image = "debian:12";
              pull_policy = "if-not-present";
              allowed_pull_policies = ["if-not-present"];
              privileged = true;
              volumes = [
               "/var/run/docker.sock:/var/run/docker.sock"
              ];
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

  # Autocleanup every 15 mins
  systemd.timers."gitlab-runner-cleanup" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "15m";
        Unit = "gitlab-runner-cleanup.service";
      };
  };
  
  systemd.services."gitlab-runner-cleanup" = {
    script = ''
      set -eu
      ${pkgs.docker}/bin/docker system prune --all --force
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
}
