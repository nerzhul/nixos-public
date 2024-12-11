{ config, pkgs, lib, ... }:
let
  kubeApiServerCfg = config.services.kubeApiServer;
  version = "v1.29.10";
in
with lib;
{
  options = {
    services.kubeApiServer = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Enable kube-apiserver static pod.'';
      };
      etcdServers = mkOption {
        default = "https://etcd:2379";
        type = types.str;
        description = ''ETCD servers URLs.'';
      };
      serviceClusterIPRange = mkOption {
        default = "10.56.0.0/16";
        type = types.str;
        description = ''Service Cluster IP Range.'';
      };
      serviceAccountIssuer = mkOption {
        default = "https://k8s-api:6443";
        type = types.str;
        description = ''Service Account Issuer URL.'';
      };
      nodePortStart = mkOption {
        default = 30000;
        type = types.int;
        description = ''NodePort start range.'';
      };
      nodePortEnd = mkOption {
        default = 32767;
        type = types.int;
        description = ''NodePort end range.'';
      };
      apiserverSAKey = mkOption {
        default = "";
        type = types.str;
        description = ''Kube-apiserver service account key.'';
      };
      etcdKey = mkOption {
        default = "";
        type = types.str;
        description = ''ETCD key.'';
      };
      etcdCert = mkOption {
        default = "";
        type = types.str;
        description = ''ETCD certificate.'';
      };
      etcdCACert = mkOption {
        default = "";
        type = types.str;
        description = ''ETCD CA certificate.'';
      };
      apiserverKey = mkOption {
        default = "";
        type = types.str;
        description = ''Kube-apiserver key.'';
      };
      apiserverCert = mkOption {
        default = "";
        type = types.str;
        description = ''Kube-apiserver certificate.'';
      };
      caCert = mkOption {
        default = "";
        type = types.str;
        description = ''CA certificate.'';
      };
      frontProxyClientKey = mkOption {
        default = "";
        type = types.str;
        description = ''Front proxy client key.'';
      };
      frontProxyClientCert = mkOption {
        default = "";
        type = types.str;
        description = ''Front proxy client certificate.'';
      };
      frontProxyCACert = mkOption {
        default = "";
        type = types.str;
        description = ''Front proxy CA certificate.'';
      };
      apiserverKubeletClientCert = mkOption {
        default = "";
        type = types.str;
        description = ''Kube-apiserver kubelet client certificate.'';
      };
      apiserverKubeletClientKey = mkOption {
        default = "";
        type = types.str;
        description = ''Kube-apiserver kubelet client key.'';
      };
      admissionPlugins = mkOption {
        default = [ "DefaultStorageClass" "DefaultTolerationSeconds" "LimitRanger" "NamespaceLifecycle" "PodNodeSelector" "PodSecurity" "ResourceQuota" "ServiceAccount" ];
        type = types.listOf types.str;
        description = ''Admission plugins.'';
      };
      authorizationMode = mkOption {
        default = [ "Node" "RBAC" ];
        type = types.listOf types.str;
        description = ''Authorization mode.'';
      };
      verbosity = mkOption {
        default = 1;
        type = types.int;
        description = ''Verbosity level.'';
      };
    };
  };
  config = mkIf kubeApiServerCfg.enable {
    environment.etc."kubernetes/pki/etcd.key".text = kubeApiServerCfg.etcdKey;
    environment.etc."kubernetes/pki/etcd.crt".text = kubeApiServerCfg.etcdCert;
    environment.etc."kubernetes/pki/etcd-ca.crt".text = kubeApiServerCfg.etcdCACert;
    environment.etc."kubernetes/pki/kube-apiserver.key".text = kubeApiServerCfg.apiserverKey;
    environment.etc."kubernetes/pki/kube-apiserver.crt".text = kubeApiServerCfg.apiserverCert;
    environment.etc."kubernetes/pki/ca.crt".text = kubeApiServerCfg.caCert;
    environment.etc."kubernetes/pki/front-proxy-client.key".text = kubeApiServerCfg.frontProxyClientKey;
    environment.etc."kubernetes/pki/front-proxy-client.crt".text = kubeApiServerCfg.frontProxyClientCert;
    environment.etc."kubernetes/pki/front-proxy-ca.crt".text = kubeApiServerCfg.frontProxyCACert;
    environment.etc."kubernetes/pki/sa.key".text = kubeApiServerCfg.apiserverSAKey;
    environment.etc."kubernetes/pki/apiserver-kubelet-client.crt".text = kubeApiServerCfg.apiserverKubeletClientCert;
    environment.etc."kubernetes/pki/apiserver-kubelet-client.key".text = kubeApiServerCfg.apiserverKubeletClientKey;
    environment.etc."kubernetes/manifests/kube-apiserver.yml".text = ''
      ---
      apiVersion: v1
      kind: Pod
      metadata:
        name: kube-apiserver
        namespace: kube-system
        annotations:
          app: kube-apiserver
      spec:
        hostNetwork: true
        dnsPolicy: Default
        priorityClassName: system-cluster-critical
        containers:
          - name: apiserver
            image: registry.k8s.io/kube-apiserver:${version}
            command:
              - kube-apiserver
              - --profiling=false
              - --allow-privileged=true
              - --enable-admission-plugins=${lib.strings.concatStringsSep "," kubeApiServerCfg.admissionPlugins}
              - --authorization-mode=${lib.strings.concatStringsSep "," kubeApiServerCfg.authorizationMode}
              - --secure-port=6443
              - --bind-address=0.0.0.0
              - --etcd-cafile=/etc/kubernetes/pki/etcd-ca.crt
              - --etcd-certfile=/etc/kubernetes/pki/etcd.crt
              - --etcd-keyfile=/etc/kubernetes/pki/etcd.key
              - --audit-log-maxage=30
              - --audit-log-maxbackup=3
              - --audit-log-maxsize=100
              - --client-ca-file=/etc/kubernetes/pki/ca.crt
              - --etcd-servers=${kubeApiServerCfg.etcdServers}
              - --service-account-key-file=/etc/kubernetes/pki/sa.key
              - --service-account-issuer=${kubeApiServerCfg.serviceAccountIssuer}
              - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
              - --service-cluster-ip-range=${kubeApiServerCfg.serviceClusterIPRange}
              - --service-node-port-range=${toString kubeApiServerCfg.nodePortStart}-${toString kubeApiServerCfg.nodePortEnd}
              - --tls-cert-file=/etc/kubernetes/pki/kube-apiserver.crt
              - --tls-private-key-file=/etc/kubernetes/pki/kube-apiserver.key
              - --enable-bootstrap-token-auth=true
              - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
              - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
              - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
              - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
              - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
              - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
              - --requestheader-username-headers=X-Remote-User
              - --requestheader-group-headers=X-Remote-Group
              - --requestheader-allowed-names=front-proxy-client
              - --requestheader-extra-headers-prefix=X-Remote-Extra-
              - --v=3
            ports:
              - name: https
                containerPort: 6443
                protocol: TCP
            volumeMounts:
              - name: pki
                mountPath: /etc/kubernetes/pki
              - name: nixstore
                mountPath: /nix/store
                readOnly: true
            livenessProbe:
              httpGet:
                path: /livez
                port: https
                scheme: HTTPS
              initialDelaySeconds: 5
              timeoutSeconds: 5
              successThreshold: 1
              failureThreshold: 3
            resources:
              requests:
                cpu: 100m
                memory: 768Mi
              limits:
                memory: 768Mi
            readinessProbe:
              httpGet:
                path: /readyz
                port: https
                scheme: HTTPS
              initialDelaySeconds: 5
              timeoutSeconds: 5
              successThreshold: 1
              failureThreshold: 3
        volumes:
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
