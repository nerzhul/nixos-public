{ config, pkgs, lib, ... }:
let
  kubeApiServerCfg = config.services.kubeApiServer;
  version = "v1.35.0";
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
      audit = {
        enable = mkOption {
          default = false;
          type = with types; bool;
          description = ''Enable audit logging.'';
        };
        policy = mkOption {
          default = "";
          type = types.str;
          description = ''Audit policy.'';
        };
        webhook = mkOption {
          default = "";
          type = types.str;
          description = ''Audit webhook kubeconfig.'';
        };
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
      apiServerDomainName = mkOption {
        default = "kubernetes.k8s.local";
        type = types.str;
        description = ''Kube-apiserver domain name.'';
      };
      apiServerIP = mkOption {
        default = "127.0.0.1";
        type = types.str;
        description = ''Kube-apiserver IP address.'';
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
    environment.etc."kubernetes/pki/kube-apiserver-csr.conf".text = ''
      [req]
      req_extensions = v3_req
      distinguished_name = req_distinguished_name
      prompt = no

      [req_distinguished_name]
      CN = kube-apiserver

      [v3_req]
      keyUsage = digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth, clientAuth
      subjectAltName = @alt_names

      [alt_names]
      DNS.1 = kubernetes
      DNS.2 = kubernetes.default
      DNS.3 = kubernetes.default.svc
      DNS.4 = kubernetes.default.svc.cluster.local
      DNS.5 = ${kubeApiServerCfg.apiServerDomainName}
      IP.1 = ${kubeApiServerCfg.apiServerIP}'';
    environment.etc."kubernetes/pki/front-proxy-client.key".text = kubeApiServerCfg.frontProxyClientKey;
    environment.etc."kubernetes/pki/front-proxy-client.crt".text = kubeApiServerCfg.frontProxyClientCert;
    environment.etc."kubernetes/pki/front-proxy-ca.crt".text = kubeApiServerCfg.frontProxyCACert;
    environment.etc."kubernetes/pki/sa.key".text = kubeApiServerCfg.apiserverSAKey;
    environment.etc."kubernetes/pki/apiserver-kubelet-client-csr.conf".text = ''
      [req]
      distinguished_name = req_distinguished_name
      req_extensions = v3_req
      prompt = no

      [req_distinguished_name]
      CN = apiserver-kubelet-client
      O = system:masters

      [v3_req]
      keyUsage = digitalSignature, keyEncipherment
      extendedKeyUsage = clientAuth
      subjectAltName = @alt_names

      [alt_names]
      DNS.1 = kubernetes
      DNS.2 = kubernetes.default
      DNS.3 = kubernetes.default.svc
      DNS.4 = kubernetes.default.svc.cluster.local
      DNS.5 = ${kubeApiServerCfg.apiServerDomainName}
      IP.1 = ${kubeApiServerCfg.apiServerIP}'';
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
        dnsPolicy: ${kubeApiServerCfg.dns.policy}
        dnsConfig:
          options:
            - name: ndots
              value: "0"
          nameservers: ${builtins.toJSON kubeApiServerCfg.dns.nameservers}
        priorityClassName: system-cluster-critical
        initContainers:
          - name: pki-init
            image: alpine/openssl:3.3.3
            command:
              - sh
              - -c
              - |
                openssl genrsa -out /etc/kubernetes/generated/pki/kube-apiserver.key 2048
                openssl req -new -key /etc/kubernetes/generated/pki/kube-apiserver.key -out /etc/kubernetes/generated/pki/kube-apiserver.csr \
                  -config /etc/kubernetes/pki/kube-apiserver-csr.conf
                openssl x509 -req -in /etc/kubernetes/generated/pki/kube-apiserver.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial \
                  -CAserial /etc/kubernetes/generated/pki/ca.srl \
                  -out /etc/kubernetes/generated/pki/kube-apiserver.crt -days 365 -extensions v3_req -extfile /etc/kubernetes/pki/kube-apiserver-csr.conf
                openssl genrsa -out /etc/kubernetes/generated/pki/apiserver-kubelet-client.key 2048
                openssl req -new -key /etc/kubernetes/generated/pki/apiserver-kubelet-client.key -out /etc/kubernetes/generated/pki/apiserver-kubelet-client.csr \
                  -config /etc/kubernetes/pki/apiserver-kubelet-client-csr.conf
                openssl x509 -req -in /etc/kubernetes/generated/pki/apiserver-kubelet-client.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial \
                  -CAserial /etc/kubernetes/generated/pki/ca.srl \
                  -out /etc/kubernetes/generated/pki/apiserver-kubelet-client.crt -days 365 -extensions v3_req -extfile /etc/kubernetes/pki/apiserver-kubelet-client-csr.conf
            volumeMounts:
              - name: pki
                mountPath: /etc/kubernetes/pki
              - name: nixstore
                mountPath: /nix/store
                readOnly: true
              - name: generated-pki
                mountPath: /etc/kubernetes/generated/pki
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
              - --tls-cert-file=/etc/kubernetes/generated/pki/kube-apiserver.crt
              - --tls-private-key-file=/etc/kubernetes/generated/pki/kube-apiserver.key
              - --enable-bootstrap-token-auth=true
              - --kubelet-client-certificate=/etc/kubernetes/generated/pki/apiserver-kubelet-client.crt
              - --kubelet-client-key=/etc/kubernetes/generated/pki/apiserver-kubelet-client.key
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
              - name: generated-pki
                mountPath: /etc/kubernetes/generated/pki
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
                memory: 1Gi
              limits:
                memory: 1Gi
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
          - name: generated-pki
            emptyDir: {}
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
  #  // (mkIf kubeApiServerCfg.audit.enable {
  #     environment.etc."kubernetes/audit-policy.yaml".text = kubeApiServerCfg.audit.policy;
  #     environment.etc."kubernetes/audit-webhook.kubeconfig".text = kubeApiServerCfg.audit.webhook;
  # });
}
