{ config, pkgs, lib, ... }:
let
  b64 = import ../util/base64.nix { inherit lib; };
  kubeSchedulerCfg = config.services.kubeScheduler;
  version = "v1.35.2";
in
with lib;
{
  options = {
    services.kubeScheduler = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Enable kube-scheduler static pod.'';
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
        description = ''API server CA certificate encoded.'';
      };
      clusterName = mkOption {
        default = "k8s";
        type = types.str;
        description = ''Bootstrap kubeconfig context name.'';
      };
    };
  };
  config = mkIf kubeSchedulerCfg.enable {
    environment.etc."kubernetes/scheduler.kubeconfig".text = ''
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${b64.toBase64 kubeSchedulerCfg.apiCACert}
    server: ${kubeSchedulerCfg.apiServerURL}
  name: ${kubeSchedulerCfg.clusterName}
contexts:
- context:
    cluster: ${kubeSchedulerCfg.clusterName}
    user: system:kube-scheduler
  name: kube-scheduler@${kubeSchedulerCfg.clusterName}
current-context: kube-scheduler@${kubeSchedulerCfg.clusterName}
kind: Config
preferences: {}
users:
- name: "system:kube-scheduler"
  user:
    client-certificate: /etc/kubernetes/generated/pki/scheduler.crt
    client-key: /etc/kubernetes/generated/pki/scheduler.key
'';
    environment.etc."kubernetes/pki/scheduler-csr.conf".text = ''
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = system:kube-scheduler
O = system:kube-scheduler

[v3_req]

[alt_names]
DNS.1 = kube-scheduler
DNS.2 = kube-scheduler.kube-system
'';
    environment.etc."kubernetes/scheduler.yaml".text = ''
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/etc/kubernetes/scheduler.kubeconfig"
leaderElection:
  leaderElect: true
enableProfiling: false
'';

    environment.etc."kubernetes/manifests/kube-scheduler.yml".text = ''
---
apiVersion: v1
kind: Pod
metadata:
  name: kube-scheduler
  namespace: kube-system
  annotations:
    app: kube-scheduler
  labels:
    component: kube-scheduler
    provider: kubernetes
spec:
  dnsPolicy: ${kubeSchedulerCfg.dns.policy}
  dnsConfig:
    options:
      - name: ndots
        value: "0"
    nameservers: ${builtins.toJSON kubeSchedulerCfg.dns.nameservers}
  hostNetwork: true
  priorityClassName: system-cluster-critical
  initContainers:
    - name: pki-init
      image: alpine/openssl:3.5.5
      command:
        - sh
        - -c
        - |
          openssl genrsa -out /etc/kubernetes/generated/pki/scheduler.key 2048
          openssl req -new -key /etc/kubernetes/pki/sa.key -out /etc/kubernetes/generated/pki/scheduler.csr \
            -config /etc/kubernetes/pki/scheduler-csr.conf
          openssl x509 -req -in /etc/kubernetes/generated/pki/scheduler.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial \
            -CAserial /etc/kubernetes/generated/pki/ca.srl \
            -out /etc/kubernetes/generated/pki/scheduler.crt -days 365 -extensions v3_req -extfile /etc/kubernetes/pki/scheduler-csr.conf
      securityContext:
        runAsNonRoot: true
        runAsUser: 10259
        runAsGroup: 10999
      volumeMounts:
        - name: pki
          mountPath: /etc/kubernetes/pki
        - name: nixstore
          mountPath: /nix/store
          readOnly: true
        - name: generated-pki
          mountPath: /etc/kubernetes/generated/pki
  containers:
    - name: scheduler
      image: registry.k8s.io/kube-scheduler:${version}
      command:
        - kube-scheduler
        - --config=/etc/kubernetes/scheduler.yaml
        - --bind-address=0.0.0.0
        - --secure-port=10259
        - --v=4
      ports:
        - name: https
          containerPort: 10259
          protocol: TCP
      resources:
        requests:
          cpu: 50m
          memory: 96Mi
        limits:
          memory: 96Mi
      volumeMounts:
        - name: config
          mountPath: /etc/kubernetes/scheduler.yaml
        - name: kubeconfig
          mountPath: /etc/kubernetes/scheduler.kubeconfig
        - name: pki
          mountPath: /etc/kubernetes/pki
        - name: nixstore
          mountPath: /nix/store
          readOnly: true
        - name: generated-pki
          mountPath: /etc/kubernetes/generated/pki
      securityContext:
        runAsNonRoot: true
        runAsUser: 10259
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
    - name: config
      hostPath:
        path: /etc/kubernetes/scheduler.yaml
        type: File
    - name: kubeconfig
      hostPath:
        path: /etc/kubernetes/scheduler.kubeconfig
        type: File
    - name: generated-pki
      emptyDir: {}
    - name: pki
      hostPath:
        path: /etc/static/kubernetes/pki
        type: Directory
    - name: nixstore
      hostPath:
        path: /nix/store
        type: Directory
      '';
  };
}