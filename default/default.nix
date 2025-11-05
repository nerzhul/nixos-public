{ config, pkgs, ... }: {
  imports = [ ./users.nix ./cache.nix ./pkg-builder.nix ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
