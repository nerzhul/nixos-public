{ config, pkgs, lib, ... }:
let
  kubeControllerManagerCfg = config.services.kubeControllerManager;
  version = "v1.29.5";
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
      clusterName = mkOption {
        default = "k8s";
        type = types.str;
        description = ''Bootstrap kubeconfig context name.'';
      };
      controllerManagerCertEncoded = mkOption {
        default = "";
        type = types.str;
        description = ''Controller Manager client certificate encoded.'';
      };
      controllerManagerKeyEncoded = mkOption {
        default = "";
        type = types.str;
        description = ''Controller Manager client key encoded.'';
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
    };
  };
  config = mkIf kubeControllerManagerCfg.enable {
    environment.etc."kubernetes/controller-manager.kubeconfig".text = ''
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${kubeControllerManagerCfg.apiCAEncoded}
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
    client-certificate-data: ${kubeControllerManagerCfg.controllerManagerCertEncoded}
    client-key-data: ${kubeControllerManagerCfg.controllerManagerKeyEncoded}
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
  hostNetwork: true
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
        - --cluster-cidr=${clusterCIDR}
        - --cluster-name=drogon
        - --service-cluster-ip-range=${serviceClusterIPRange}
        - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt
        - --cluster-signing-key-file=/etc/kubernetes/pki/ca.key
        - --root-ca-file=/etc/kubernetes/pki/ca.crt
        - --use-service-account-credentials=true
        - --allocate-node-cidrs=true
        - --cluster-signing-duration=${clusterSigningDuration}
        - --logging-format=json
        - --v=2
        - --feature-gates=
      ports:
        - name: https
          containerPort: 10257
          protocol: TCP
      volumeMounts:
        - name: kubeconfig
          mountPath: /etc/kubernetes/controller-manager.kubeconfig
        - name: pki
          mountPath: /etc/kubernetes/pki
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
    - name: kubeconfig
      hostPath:
        path: /etc/kubernetes/controller-manager.kubeconfig
        type: File
    - name: pki
      hostPath:
        path: /etc/kubernetes/pki
        type: Directory
      '';
  };
}