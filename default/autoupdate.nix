{
  systemd.services.nix-channel-update = {
    description = "Update Nix channels";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/nix-channel --update";
    };
  };

  systemd.timers.nix-channel-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";   # ou weekly, etc.
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };
}