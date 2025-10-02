{ config, pkgs, lib, ... }:

let
  brokerAppName = "home-bt-broker";
  audioUserID = 1001;
  homeBtBroker = pkgs.buildGoModule rec {
    pname = "${brokerAppName}";
    version = "unstable";

    src = pkgs.fetchFromGitHub {
      owner = "nerzhul";
      repo = "home-bt-broker";
      rev = "main";
      sha256 = "sha256-XpsiPE2IIaJ0EzABOOzpiKzSP2BS/g/h2JGYBsHMu5M=";
    };

    vendorHash = null;

    goPackagePath = "github.com/nerzhul/home-bt-broker";
    subPackages = [ "cmd/home-bt-broker" ];

    postInstall = ''
      mkdir -p $out/share/${brokerAppName} $out/share/${brokerAppName}/internal/handlers
      cp -r ${src}/internal/handlers/static $out/share/${brokerAppName}/internal/handlers/
      cp -r ${src}/migrations $out/share/${brokerAppName}/
    '';
  };
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/home-bt-broker 0755 audio-broker audio -"
  ];
  systemd.services.home-bt-broker = {
    description = "Home Bluetooth Sound Broker";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    preStart = ''
      cp -r --no-preserve=mode,ownership ${homeBtBroker}/share/${brokerAppName}/migrations /var/lib/home-bt-broker/
      cp -r --no-preserve=mode,ownership ${homeBtBroker}/share/${brokerAppName}/internal /var/lib/home-bt-broker/
    '';

    serviceConfig = {
      ExecStart = "${homeBtBroker}/bin/${brokerAppName}";
      Restart = "always";
      User = "audio-broker";
      Group = "audio";
      WorkingDirectory = "/var/lib/home-bt-broker";
      Environment = "XDG_RUNTIME_DIR=/run/user/${toString audioUserID}";
    };

    path = [pkgs.pipewire];
  };
}
