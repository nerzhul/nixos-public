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
	  mkdir -p $out/etc/containerd/
	  install -Dm400 configs/containerd-config.toml $out/etc/containerd/config.toml
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
	environment.etc."containerd/config.toml".text = lib.mkForce ''
	root = "/var/lib/containerd"
	state = "/run/containerd"
	oom_score = 0

	[grpc]
	address = "/run/containerd/containerd.sock"
	uid = 0
	gid = 0
	max_recv_message_size = 16777216
	max_send_message_size = 16777216

	[debug]
	address = ""
	uid = 0
	gid = 0
	level = ""

	[metrics]
	address = ""
	grpc_histogram = false

	[cgroup]
	path = ""

	[plugins]
	[plugins.cgroups]
		no_prometheus = false
	[plugins.cri]
		stream_server_address = "127.0.0.1"
		stream_server_port = "0"
		enable_selinux = false
		sandbox_image = "k8s.gcr.io/pause:3.2"
		stats_collect_period = 10
		systemd_cgroup = false
		enable_tls_streaming = false
		max_container_log_line_size = 16384
		[plugins.cri.containerd]
		snapshotter = "overlayfs"
		no_pivot = false
		[plugins.cri.containerd.default_runtime]
			runtime_type = "io.containerd.runc.v2"
			runtime_engine = ""
			runtime_root = ""
		[plugins.cri.containerd.untrusted_workload_runtime]
			runtime_type = ""
			runtime_engine = ""
			runtime_root = ""
		[plugins.cri.cni]
		bin_dir = "/opt/cni/bin"
		conf_dir = "/etc/cni/net.d"
		conf_template = ""
		[plugins.cri.registry]
		[plugins.cri.registry.mirrors]
			[plugins.cri.registry.mirrors."docker.io"]
			endpoint = ["https://registry-1.docker.io"]
		[plugins.cri.x509_key_pair_streaming]
		tls_cert_file = ""
		tls_key_file = ""
	[plugins.diff-service]
		default = ["walking"]
	[plugins.linux]
		shim = "containerd-shim"
		runtime = "runc"
		runtime_root = ""
		no_shim = false
		shim_debug = false
	[plugins.opt]
		path = "/opt/containerd"
	[plugins.restart]
		interval = "10s"
	[plugins.scheduler]
		pause_threshold = 0.02
		deletion_threshold = 0
		mutation_threshold = 100
		schedule_delay = "0s"
		startup_delay = "100ms"
	'';
	
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
