{ config, pkgs, ... }: {
  imports = [ ./users.nix ./cache.nix ./pkg-builder.nix ./autoupdate.nix ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    #settings.PermitRootLogin = "yes";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.journald.settings.Journal = {
    Storage = "volatile";
    RuntimeMaxUse = "128M";
    SystemMaxUse = "386M";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.tmp.useTmpfs = true;
}
