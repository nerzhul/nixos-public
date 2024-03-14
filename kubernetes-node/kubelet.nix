{ config, pkgs, lib, ... }:
let
  kubeletCfg = config.services.kubelet;
  kubernetes = with pkgs; buildGoModule rec {
    pname = "kubernetes";
    version = "1.28.7";

    src = fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      hash = "sha256-Qhx5nB4S5a8NlRhxQrD1U4oOCMLxJ9XUk2XemwAwe5k=";
    };

    vendorHash = null;

    doCheck = false;

    nativeBuildInputs = [ makeWrapper which rsync installShellFiles ];

    outputs = [ "out" "man" "pause" ];

    WHAT = [ "cmd/kubelet" ];

    buildPhase = ''
      runHook preBuild
      substituteInPlace "hack/update-generated-docs.sh" --replace "make" "make SHELL=${runtimeShell}"
      patchShebangs ./hack
      make "SHELL=${runtimeShell}" "WHAT=$WHAT"
      ./hack/update-generated-docs.sh
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      for p in $WHAT; do
        install -D _output/local/go/bin/''${p##*/} -t $out/bin
      done

      cc build/pause/linux/pause.c -o pause
      install -D pause -t $pause/bin

      rm docs/man/man1/kubectl*
      installManPage docs/man/man1/*.[1-9]

      ln -s ${kubectl}/bin/kubectl $out/bin/kubectl

      runHook postInstall
    '';

    meta = with lib; {
      description = "Production-Grade Container Scheduling and Management";
      license = licenses.asl20;
      homepage = "https://kubernetes.io";
      maintainers = with maintainers; [ ] ++ teams.kubernetes.members;
      platforms = platforms.linux;
    };

    passthru.tests = nixosTests.kubernetes // { inherit kubectl; };
  };
in
with lib;
{
  options = {
    services.kubelet = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Starts kubelet daemon.'';
      };
    };
  };
  config = mkIf kubeletCfg.enable {
    swapDevices = lib.mkForce [ ];
    boot.kernel = {
      sysctl = {
        "net.nf_conntrack_max" = 524288;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.core.rmem_default" = 4194304;
        "net.core.wmem_default" = 4194304;
        "net.core.somaxconn" = 2048;
        "fs.file-max" = 655360;
        "net.ipv4.tcp_wmem" = "4096 12582912 16777216";
        "net.ipv4.tcp_rmem" = "4096 12582912 16777216";
        "net.ipv4.udp_mem" = "65536 131072 262144";
        "net.ipv4.tcp_max_syn_backlog" = "1024";
      };
    };

    systemd.services.kubelet = {
      enable = true;
      description = "Kubernetes Kubelet";
      wantedBy = [ "multi-user.target" ];
      documentation = [ "https://github.com/kubernetes/kubernetes" ];
      after = [ "network.target" ];
      requires = [ "network-online.target" ];
      path = [ pkgs.mount pkgs.umount ];

      serviceConfig = {
        ExecStart = ''${kubernetes}/bin/kubelet \
        --bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \
        --kubeconfig=/etc/kubernetes/kubelet.conf \
        --config=/etc/kubernetes/kubelet.yml \
        --cert-dir=/etc/kubernetes/pki \
        --fail-swap-on=false \
        --container-runtime-endpoint=unix:///run/containerd/containerd.sock'';
        Restart = "always";
        RestartSec = 10;
        OOMScoreAdjust = -999;
        LimitNOFILE = 1048576;
        LimitNPROC = "infinity";
        LimitCORE = "infinity";
      };
    };
  };
}
