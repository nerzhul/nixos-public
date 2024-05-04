{ config, pkgs, lib, ... }:
let
  kubeletCfg = config.services.kubelet;
  kubernetes = with pkgs; buildGoModule rec {
    pname = "kubernetes";
    version = "1.29.3";

    src = fetchFromGitHub {
      owner = "kubernetes";
      repo = "kubernetes";
      rev = "v${version}";
      hash = "sha256-mtYxFy2d892uMLrtaR6ao07gjbThuGa7bzauwvJ0WOo=";
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
      dnsClusterIP = mkOption {
        default = "10.0.0.1";
        type = types.str;
        description = ''Cluster DNS IP address.'';
      };
      clusterDomain = mkOption {
        default = "cluster.local";
        type = types.str;
        description = ''Cluster DNS domain.'';
      };
      systemReservedCPU = mkOption {
        default = "250m";
        type = types.str;
        description = ''Reserved CPU for system.'';
      };
      systemReservedMemory = mkOption {
        default = "1Gi";
        type = types.str;
        description = ''Reserved memory for system.'';
      };
      apiServerURL = mkOption {
        default = "https://localhost:6443";
        type = types.str;
        description = ''API server URL.'';
      };
      apiCAEncoded = mkOption {
        default = "";
        type = types.str;
        description = ''API server CA certificate encoded.'';
      };
      bootstrapConfigClusterName = mkOption {
        default = "k8s";
        type = types.str;
        description = ''Bootstrap kubeconfig context name.'';
      };
      bootstrapToken = mkOption {
        default = "setme.todo";
        type = types.str;
        description = ''Bootstrap token.'';
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

    # Disable firewall
    networking.firewall.enable = false;
    environment.etc."kubernetes/kubelet.yml".text = ''
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authorization:
  mode: Webhook
authentication:
  webhook:
    enabled: yes
  x509:
    clientCAFile: "/etc/kubernetes/pki/ca.crt"
cgroupDriver: "cgroupfs"
cgroupRoot: "/"
staticPodPath: "/etc/kubernetes/manifests"
evictionHard:
  nodefs.available: "1G"
  nodefs.inodesFree: "5%"
  imagefs.available: "1G"
  imagefs.inodesFree: "5%"
  memory.available: "128Mi"
systemReserved:
  cpu: "${kubeletCfg.systemReservedCPU}"
  memory: "${kubeletCfg.systemReservedMemory}"
clusterDomain: "${kubeletCfg.clusterDomain}"
clusterDNS:
  - "${kubeletCfg.dnsClusterIP}"
rotateCertificates: true
'';
    environment.etc."kubernetes/bootstrap.kubeconfig".text = ''
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${kubeletCfg.apiCAEncoded}
    server: ${kubeletCfg.apiServerURL}
  name: ${kubeletCfg.bootstrapConfigClusterName}
contexts:
- context:
    cluster: ${kubeletCfg.bootstrapConfigClusterName}
    user: kubelet-bootstrap
  name: kubelet-bootstrap@${kubeletCfg.bootstrapConfigClusterName}
current-context: kubelet-bootstrap@${kubeletCfg.bootstrapConfigClusterName}
kind: Config
preferences: {}
users:
- name: kubelet-bootstrap
  user:
    token: ${kubeletCfg.bootstrapToken}
'';

    systemd.services.kubelet = {
      enable = true;
      description = "Kubernetes Kubelet";
      wantedBy = [ "multi-user.target" ];
      documentation = [ "https://github.com/kubernetes/kubernetes" ];
      after = [ "network.target" ];
      requires = [ "network-online.target" ];
      path = [ pkgs.mount pkgs.umount pkgs.nfs-utils ];

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
