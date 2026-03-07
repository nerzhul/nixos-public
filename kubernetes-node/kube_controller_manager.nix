{ config, pkgs, lib, ... }:
let
  kubeControllerManagerCfg = config.services.kubeControllerManager;
  version = "v1.35.2";
  b64 = import ../util/base64.nix { inherit lib; };
in
with lib;
{
  options = {
    services.kubeControllerManager = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Enable kube-controller-manager static pod.'';
      };
      dns = {
        policy = mkOption {
          default = "Default";
          type = types.str;
          description = ''DNS policy.'';
        };
        nameservers = mkOption {
          default = ["::1" "127.0.0.1"];
          type = types.listOf types.str;
          description = ''DNS nameservers.'';
        };
      };
      apiServerURL = mkOption {
        default = "https://localhost:6443";
        type = types.str;
        description = ''API server URL.'';
      };
      apiCACert = mkOption {
        default = "";
        type = types.str;
        description = ''API server CA certificate.'';
      };
      clusterName = mkOption {
        default = "k8s";
        type = types.str;
        description = ''Bootstrap kubeconfig context name.'';
      };
      controllerManagerKey = mkOption {
        default = "";
        type = types.str;
        description = ''Controller Manager client key.'';
      };
	  clusterCIDR = mkOption {
		  default = "10.55.0.0/16";
		  type = types.str;
		  description = ''Cluster CIDR.'';
	  };
	  serviceClusterIPRange = mkOption {
		  default = "10.56.0.0/16";
		  type = types.str;
		  description = ''Service Cluster IP Range.'';
	  };
	  clusterSigningDuration = mkOption {
		default = "8760h0m0s";
		type = types.str;
		description = ''Cluster CSR signing duration.'';
	  };
	  verbosity = mkOption {
		default = 1;
		type = types.int;
		description = ''Verbosity level.'';
	  };
    };
  };
  config = mkIf kubeControllerManagerCfg.enable {
    environment.etc."kubernetes/controller-manager.kubeconfig".text = ''
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${b64.toBase64 kubeControllerManagerCfg.apiCACert}
    server: ${kubeControllerManagerCfg.apiServerURL}
  name: ${kubeControllerManagerCfg.clusterName}
contexts:
- context:
    cluster: ${kubeControllerManagerCfg.clusterName}
    user: system:kube-controller-manager
  name: kube-controller-manager@${kubeControllerManagerCfg.clusterName}
current-context: kube-controller-manager@${kubeControllerManagerCfg.clusterName}
kind: Config
preferences: {}
users:
- name: "system:kube-controller-manager"
  user:
    client-certificate: /etc/kubernetes/generated/pki/kube-controllermanager.crt
    client-key: /etc/kubernetes/pki/sa.key
'';
	environment.etc."kubernetes/pki/sa.key".text = kubeControllerManagerCfg.controllerManagerKey;
  environment.etc."kubernetes/pki/kube-controllermanager-csr.conf".text = ''
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = system:kube-controller-manager
O = system:kube-controller-manager

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = kube-controller-manager
DNS.2 = kube-controller-manager.kube-system
'';
  environment.etc."kubernetes/manifests/kube-controller-manager.yml".text = ''
---
apiVersion: v1
kind: Pod
metadata:
  name: kube-controller-manager
  namespace: kube-system
  annotations:
    app: kube-controller-manager
  labels:
    component: kube-controller-manager
    provider: kubernetes
spec:
  dnsPolicy: ${kubeControllerManagerCfg.dns.policy}
  dnsConfig:
    options:
      - name: ndots
        value: "0"
    nameservers: ${builtins.toJSON kubeControllerManagerCfg.dns.nameservers}
  hostNetwork: true
  priorityClassName: system-cluster-critical
  initContainers:
    - name: pki-init
      image: alpine/openssl:3.3.3
      command:
        - sh
        - -c
        - |
          openssl req -new -key /etc/kubernetes/pki/sa.key -out /etc/kubernetes/generated/pki/kube-controllermanager.csr \
            -config /etc/kubernetes/pki/kube-controllermanager-csr.conf
          openssl x509 -req -in /etc/kubernetes/generated/pki/kube-controllermanager.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial \
            -CAserial /etc/kubernetes/generated/pki/ca.srl \
            -out /etc/kubernetes/generated/pki/kube-controllermanager.crt -days 365 -extensions v3_req -extfile /etc/kubernetes/pki/kube-controllermanager-csr.conf
      volumeMounts:
        - name: pki
          mountPath: /etc/kubernetes/pki
        - name: nixstore
          mountPath: /nix/store
          readOnly: true
        - name: generated-pki
          mountPath: /etc/kubernetes/generated/pki
  containers:
    - name: controller-manager
      image: registry.k8s.io/kube-controller-manager:${version}
      command:
        - kube-controller-manager
        - --profiling=false
        - --kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
        - --authentication-kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
        - --authorization-kubeconfig=/etc/kubernetes/controller-manager.kubeconfig
        - --bind-address=0.0.0.0
        - --leader-elect=true
        - --controllers=*,bootstrapsigner,tokencleaner
        - --service-account-private-key-file=/etc/kubernetes/pki/sa.key
        - --cluster-cidr=${kubeControllerManagerCfg.clusterCIDR}
        - --cluster-name=drogon
        - --service-cluster-ip-range=${kubeControllerManagerCfg.serviceClusterIPRange}
        - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt
        - --cluster-signing-key-file=/etc/kubernetes/pki/ca.key
        - --root-ca-file=/etc/kubernetes/pki/ca.crt
        - --use-service-account-credentials=true
        - --allocate-node-cidrs=true
        - --cluster-signing-duration=${kubeControllerManagerCfg.clusterSigningDuration}
        - --logging-format=json
        - --v=${builtins.toString kubeControllerManagerCfg.verbosity}
        - --feature-gates=
      ports:
        - name: https
          containerPort: 10257
          protocol: TCP
      resources:
        requests:
          cpu: 100m
          memory: 196Mi
        limits:
          memory: 196Mi
      volumeMounts:
        - name: kubeconfig
          mountPath: /etc/kubernetes/controller-manager.kubeconfig
        - name: pki
          mountPath: /etc/kubernetes/pki
        - name: nixstore
          mountPath: /nix/store
          readOnly: true
        - name: generated-pki
          mountPath: /etc/kubernetes/generated/pki
      securityContext:
        runAsNonRoot: true
        runAsUser: 10257
        runAsGroup: 10999
      livenessProbe:
        httpGet:
          path: /healthz
          port: https
          scheme: HTTPS
        initialDelaySeconds: 2
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 3
      readinessProbe:
        httpGet:
          path: /healthz
          port: https
          scheme: HTTPS
        initialDelaySeconds: 2
        timeoutSeconds: 5
        successThreshold: 1
        failureThreshold: 3
  volumes:
    - name: generated-pki
      emptyDir: {}
    - name: kubeconfig
      hostPath:
        path: /etc/kubernetes/controller-manager.kubeconfig
        type: File
    - name: pki
      hostPath:
        path: /etc/static/kubernetes/pki
        type: Directory
    # Horrible hack to remove in the future
    - name: nixstore
      hostPath:
        path: /nix/store
        type: Directory
      '';
  };
}