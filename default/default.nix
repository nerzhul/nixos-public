{ config, pkgs, ... }: {
  imports = [ ./users.nix ./cache.nix ./pkg-builder.nix ./autoupdate.nix ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    #settings.PermitRootLogin = "yes";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=128M
  '';

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
