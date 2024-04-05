{ config, pkgs, lib, ... }:
let
  cfg = config.services.containerd;
  containerd = with pkgs; buildGoModule rec {
    pname = "containerd";
    version = "1.7.13";

    src = fetchFromGitHub {
      owner = "containerd";
      repo = "containerd";
      rev = "v${version}";
      hash = "sha256-y3CYDZbA2QjIn1vyq/p1F1pAVxQHi/0a6hGWZCRWzyk=";
    };

    vendorHash = null;

    nativeBuildInputs = [ go-md2man installShellFiles util-linux ];

    buildInputs = [ ];

    BUILDTAGS = [ "no_btrfs" ];

    buildPhase = ''
      runHook preBuild
      patchShebangs .
      make binaries "VERSION=v${version}" "REVISION=${src.rev}"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm555 bin/* -t $out/bin
      installShellCompletion --bash contrib/autocomplete/ctr
      installShellCompletion --zsh --name _ctr contrib/autocomplete/zsh_autocomplete
      runHook postInstall
    '';

    passthru.tests = { inherit (nixosTests) docker; } // kubernetes.tests;

    meta = with lib; {
      changelog = "https://github.com/containerd/containerd/releases/tag/${src.rev}";
      homepage = "https://containerd.io/";
      description = "A daemon to control runC";
      license = licenses.asl20;
      maintainers = with maintainers; [ offline vdemeester endocrimes ];
      platforms = platforms.linux;
    };
  };
in

with lib;

{
  options = {
    services.containerd = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Starts containerd daemon.'';
      };
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ containerd ];
    boot.kernel = {
      sysctl = {
        "net.ipv4.ip_forward" = true;
      };
    };

    systemd.services.containerd = {
      enable = true;
      description = "containerd container runtime";
      wantedBy = [ "multi-user.target" ];
      documentation = [ "https://containerd.io" ];
      after = [ "network.target" ];
      path = [ pkgs.runc ];

      serviceConfig = {
        ExecStartPre = "${pkgs.kmod}/bin/modprobe overlay";
        ExecStart = "${containerd}/bin/containerd --config /etc/containerd/config.toml";
        Restart = "always";
        RestartSec = 5;
        Delegate = "yes";
        KillMode = "process";
        OOMScoreAdjust = -999;
        LimitNOFILE = 1048576;
        # Having non-zero Limit*s causes performance problems due to accounting overhead
        # in the kernel. We recommend using cgroups to do container-local accounting.
        LimitNPROC = "infinity";
        LimitCORE = "infinity";
      };
    };
  };
}
