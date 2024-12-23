{ config, pkgs, lib, ... }:
let
  version = "v0.13.6-amd64";
  version-postgres = "17.2";
  kineCfg = config.services.kine;
in
with lib;
{
  options = {
    services.kine = {
      enable = mkOption {
        default = false;
        type = with types; bool;
        description = ''Enable kine static pod.'';
      };

      kineUid = mkOption {
        default = 2379;
        type = with types; int;
        description = ''UID for the kine container.'';
      };

      kineGid = mkOption {
        default = 2379;
        type = with types; int;
        description = ''GID for the kine container.'';
      };

      kineEtcdKey = mkOption {
        type = types.str;
        description = ''Kine ETCD key.'';
      };

      kineEtcdCert = mkOption {
        type = types.str;
        description = ''Kine ETCD certificate.'';
      };

      pgUser = mkOption {
        default = "kine";
        type = with types; str;
        description = ''User for the kine database.'';
      };

      pgPassword = mkOption {
        default = "";
        type = with types; str;
        description = ''Password for the kine database.'';
      };

      pgDatabase = mkOption {
        default = "kine";
        type = with types; str;
        description = ''Database name for the kine database.'';
      };

      pgUid = mkOption {
        default = 5432;
        type = with types; int;
        description = ''UID for the kine PG database.'';
      };

      pgGid = mkOption {
        default = 5432;
        type = with types; int;
        description = ''GID for the kine PG database.'';
      };
    };
  };

  config = mkIf kineCfg.enable {
    system.activationScripts.makeKineDir =
      ''
        mkdir -p /var/lib/kine /etc/kine
        chown -R ${toString kineCfg.pgUid}:${toString kineCfg.pgGid} /var/lib/kine
        chown -R ${toString kineCfg.kineUid}:${toString kineCfg.kineGid} /etc/kine
      '';

    environment.etc."kine/etcd.crt".text = kineCfg.kineEtcdCert;
    environment.etc."kine/etcd.key".text = kineCfg.kineEtcdKey;

    environment.etc."kubernetes/manifests/kine-etcd.yml".text = ''
      ---
      apiVersion: v1
      kind: Pod
      metadata:
        name: kine-etcd
        namespace: kube-system
        annotations:
          app: kine
      spec:
        hostNetwork: true
        dnsPolicy: Default
        priorityClassName: system-cluster-critical
        containers:
          - name: kine
            image: docker.io/rancher/kine:${version}
            command:
              - kine
              - "-endpoint=postgres://${kineCfg.pgUser}:${kineCfg.pgPassword}@localhost:5432/${kineCfg.pgDatabase}?sslmode=disable"
              - "-listen-address=0.0.0.0:2379"
              - "-server-cert-file=/etc/kine/etcd.crt"
              - "-server-key-file=/etc/kine/etcd.key"
            ports:
              - name: https
                containerPort: 2379
                protocol: TCP
              - name: metrics
                containerPort: 8080
                protocol: TCP
            livenessProbe:
              httpGet:
                path: /metrics
                port: metrics
                scheme: HTTPS
              initialDelaySeconds: 5
              timeoutSeconds: 5
              successThreshold: 1
              failureThreshold: 3
            resources:
              requests:
                cpu: 50m
                memory: 128Mi
              limits:
                memory: 128Mi
            securityContext:
              runAsNonRoot: true
              runAsUser: ${toString kineCfg.kineUid}
              runAsGroup: ${toString kineCfg.kineGid}
            readinessProbe:
              httpGet:
                path: /metrics
                port: metrics
                scheme: HTTPS
              initialDelaySeconds: 5
              timeoutSeconds: 5
              successThreshold: 1
              failureThreshold: 3
            volumeMounts:
              - name: kine-config
                mountPath: /etc/kine
                readOnly: true
              - name: nixstore
                mountPath: /nix/store
                readOnly: true
          - name: postgres
            image: docker.io/postgres:${version-postgres}
            env:
              - name: POSTGRES_USER
                value: ${kineCfg.pgUser}
              - name: POSTGRES_PASSWORD
                value: ${kineCfg.pgPassword}
              - name: POSTGRES_DB
                value: ${kineCfg.pgDatabase}
            ports:
              - name: postgres
                containerPort: 5432
                protocol: TCP
            resources:
              requests:
                cpu: 50m
                memory: 256Mi
              limits:
                memory: 256Mi
            securityContext:
              runAsNonRoot: true
              runAsUser: ${toString kineCfg.pgUid}
              runAsGroup: ${toString kineCfg.pgGid}
            volumeMounts:
              - name: kine-data
                mountPath: /var/lib/postgresql/data
        volumes:
          - name: kine-data
            hostPath:
              path: /var/lib/kine
              type: Directory
          - name: kine-config
            hostPath:
              path: /etc/static/kine
              type: Directory
          # Horrible hack to remove in the future
          - name: nixstore
            hostPath:
              path: /nix/store
              type: Directory
    '';
  };
}
