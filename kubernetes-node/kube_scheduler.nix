{ config, pkgs, lib, ... }:
let
  kubeSchedulerCfg = config.services.kubeScheduler;
  version = "v1.29.5";
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
    };
  };
  config = mkIf kubeSchedulerCfg.enable {
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
  hostNetwork: true
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
      volumeMounts:
        - name: config
          mountPath: /etc/kubernetes/scheduler.yaml
        - name: kubeconfig
          mountPath: /etc/kubernetes/scheduler.kubeconfig
        - name: pki
          mountPath: /etc/kubernetes/pki
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
    - name: pki
      hostPath:
        path: /etc/kubernetes/pki
        type: Directory
      '';
  };
}