# Kubernetes Authentication Setup for External Prometheus

This guide explains how to configure authentication for Prometheus (running on xsvr1) to scrape metrics from the Talos Kubernetes cluster.

## Problem

Kubernetes endpoints like the API server (port 6443) and kubelet (port 10250) require authentication. Without proper credentials, Prometheus receives 401/403 errors when attempting to scrape these endpoints.

## Solution Overview

We create a dedicated ServiceAccount in Kubernetes with read-only permissions, extract its bearer token, and configure Prometheus to use this token for authentication.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Kubernetes Cluster                                          │
│                                                              │
│  ┌──────────────────────────────────────┐                  │
│  │ ServiceAccount: prometheus-external  │                  │
│  │ Namespace: monitoring                │                  │
│  └──────────────────────────────────────┘                  │
│                    │                                         │
│                    │ (RBAC)                                  │
│                    ▼                                         │
│  ┌──────────────────────────────────────┐                  │
│  │ ClusterRole: prometheus-external     │                  │
│  │ - Read nodes, pods, services         │                  │
│  │ - Access /metrics endpoints          │                  │
│  └──────────────────────────────────────┘                  │
│                    │                                         │
│                    │ (generates)                             │
│                    ▼                                         │
│  ┌──────────────────────────────────────┐                  │
│  │ Secret: prometheus-external-token    │                  │
│  │ Type: kubernetes.io/service-account  │                  │
│  │ Contains: JWT bearer token           │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
                     │
                     │ (extracted via script)
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ xsvr1 (NixOS)                                               │
│                                                              │
│  /var/lib/prometheus/k8s-token  (bearer token file)        │
│                    │                                         │
│                    │ (read by)                               │
│                    ▼                                         │
│  ┌──────────────────────────────────────┐                  │
│  │ Prometheus Scrape Jobs:              │                  │
│  │ - kubelet (port 10250)               │                  │
│  │ - kubernetes-apiserver (port 6443)   │                  │
│  │                                       │                  │
│  │ authorization:                        │                  │
│  │   type: Bearer                        │                  │
│  │   credentials_file:                   │                  │
│  │     /var/lib/prometheus/k8s-token     │                  │
│  └──────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Setup Steps

### Step 1: Deploy ServiceAccount to Kubernetes (Flux)

The ServiceAccount and RBAC resources are located in:
```
flux/apps/prometheus-sa/
├── namespace-monitoring.yaml
├── serviceaccount-prometheus.yaml
├── clusterrole-prometheus.yaml
├── clusterrolebinding-prometheus.yaml
├── secret-prometheus-token.yaml
├── kustomization.yaml
└── kustomization-prometheus-sa.yaml
```

**Deploy via Flux:**

1. Commit and push the prometheus-sa directory to git:
   ```bash
   cd ~/Repositories/HomeProd/flux
   git add apps/prometheus-sa/
   git commit -m "Add Prometheus ServiceAccount for external scraping"
   git push
   ```

2. Add the Kustomization to the apps directory:
   ```bash
   # Edit flux/apps/kustomization.yaml and add:
   # - ./prometheus-sa/kustomization-prometheus-sa.yaml
   ```

3. Wait for Flux to reconcile or force it:
   ```bash
   flux reconcile kustomization flux-system --with-source
   ```

4. Verify the resources were created:
   ```bash
   kubectl get sa -n monitoring prometheus-external
   kubectl get secret -n monitoring prometheus-external-token
   kubectl get clusterrole prometheus-external
   kubectl get clusterrolebinding prometheus-external
   ```

### Step 2: Extract the Bearer Token

Run the extraction script on xsvr1 (or any machine with kubectl access):

```bash
# Make the script executable
chmod +x ~/Repositories/HomeProd/nix/modules/services/monitoring/scripts/extract-k8s-token.sh

# Run the script
~/Repositories/HomeProd/nix/modules/services/monitoring/scripts/extract-k8s-token.sh
```

**What the script does:**
1. Extracts the token from the `prometheus-external-token` Secret
2. Base64 decodes it
3. Saves it to `/var/lib/prometheus/k8s-token`
4. Sets proper permissions (600, owned by prometheus user)

**Manual extraction (if needed):**
```bash
kubectl get secret prometheus-external-token -n monitoring \
  -o jsonpath='{.data.token}' | base64 -d | \
  sudo tee /var/lib/prometheus/k8s-token > /dev/null

sudo chown prometheus:prometheus /var/lib/prometheus/k8s-token
sudo chmod 600 /var/lib/prometheus/k8s-token
```

### Step 3: Verify Token Works

Test the token before reloading Prometheus:

```bash
# Test API server access
curl -k -H "Authorization: Bearer $(cat /var/lib/prometheus/k8s-token)" \
  https://172.20.3.10:6443/metrics

# Test kubelet access on first node
curl -k -H "Authorization: Bearer $(cat /var/lib/prometheus/k8s-token)" \
  https://172.20.3.10:10250/metrics
```

Both commands should return Prometheus-format metrics. If you get 401/403, check the RBAC permissions.

### Step 4: Deploy Updated Prometheus Configuration

The Prometheus scrape configs have been updated to use bearer token authentication:

```nix
# nix/modules/services/monitoring/prometheus.nix

# Kubelet scrape config
{
  job_name = "kubelet";
  scheme = "https";
  tls_config = {
    insecure_skip_verify = true;
  };
  authorization = {
    type = "Bearer";
    credentials_file = "/var/lib/prometheus/k8s-token";  # <-- Token file
  };
  static_configs = [ ... ];
}

# API server scrape config
{
  job_name = "kubernetes-apiserver";
  scheme = "https";
  tls_config = {
    insecure_skip_verify = true;
  };
  authorization = {
    type = "Bearer";
    credentials_file = "/var/lib/prometheus/k8s-token";  # <-- Token file
  };
  static_configs = [ ... ];
}
```

Deploy the updated configuration:

```bash
cd ~/Repositories/HomeProd/nix

# Rebuild NixOS configuration on xsvr1
nixos-rebuild switch --flake .#xsvr1 --target-host xsvr1.lan --use-remote-sudo

# Or if running on xsvr1 directly:
sudo nixos-rebuild switch
```

### Step 5: Verify Prometheus Targets

After Prometheus reloads:

1. Navigate to: http://xsvr1:9090/targets
2. Check the following jobs are now "UP":
   - `kubelet` (3 targets: 172.20.3.10:10250, .20:10250, .30:10250)
   - `kubernetes-apiserver` (1 target: 172.20.3.10:6443)

If targets show errors:
- Check `/var/lib/prometheus/k8s-token` exists and has correct permissions
- Verify token content with curl test above
- Check Prometheus logs: `journalctl -u prometheus -f`

---

## Token Lifecycle Management

### Token Expiration

ServiceAccount tokens created via Secret manifest (type `kubernetes.io/service-account-token`) are **long-lived and do not expire** by default in Kubernetes 1.24+.

However, if you need to rotate the token:

1. Delete the existing secret:
   ```bash
   kubectl delete secret prometheus-external-token -n monitoring
   ```

2. Flux will automatically recreate it (if using GitOps)

   OR manually recreate:
   ```bash
   kubectl apply -f flux/apps/prometheus-sa/secret-prometheus-token.yaml
   ```

3. Re-run the token extraction script:
   ```bash
   ~/Repositories/HomeProd/nix/modules/services/monitoring/scripts/extract-k8s-token.sh
   ```

4. Reload Prometheus:
   ```bash
   sudo systemctl reload prometheus
   ```

### Automated Token Refresh (Optional)

To automatically refresh the token, you can create a systemd timer:

```nix
# In prometheus.nix or a separate module
systemd.timers.prometheus-token-refresh = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "weekly";
    Persistent = true;
  };
};

systemd.services.prometheus-token-refresh = {
  script = ''
    ${pkgs.bash}/bin/bash /path/to/extract-k8s-token.sh
    ${pkgs.systemd}/bin/systemctl reload prometheus
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "root";
  };
};
```

---

## RBAC Permissions Explained

The `prometheus-external` ClusterRole grants minimal read-only permissions:

```yaml
rules:
  # Read node information and metrics
  - apiGroups: [""]
    resources:
      - nodes
      - nodes/metrics      # Kubelet metrics
      - nodes/stats        # Kubelet stats
      - nodes/proxy        # Kubelet proxy
    verbs: ["get", "list", "watch"]

  # Read services, endpoints, pods (for service discovery)
  - apiGroups: [""]
    resources:
      - services
      - endpoints
      - pods
    verbs: ["get", "list", "watch"]

  # Access API server /metrics endpoint
  - nonResourceURLs:
      - /metrics
      - /metrics/cadvisor
    verbs: ["get"]
```

**Security considerations:**
- ✅ Read-only access (no create, update, delete permissions)
- ✅ Limited to metrics endpoints
- ✅ No access to secrets or sensitive data
- ✅ Token stored with 600 permissions on xsvr1

---

## Troubleshooting

### Error: "server returned HTTP status 401 Unauthorized"

**Cause:** Token not found or invalid

**Fix:**
```bash
# Check token file exists
ls -la /var/lib/prometheus/k8s-token

# Verify token content (should be a long JWT string)
cat /var/lib/prometheus/k8s-token

# Re-extract token
~/Repositories/HomeProd/nix/modules/services/monitoring/scripts/extract-k8s-token.sh

# Reload Prometheus
sudo systemctl reload prometheus
```

### Error: "server returned HTTP status 403 Forbidden"

**Cause:** Token is valid but lacks permissions

**Fix:**
```bash
# Check ClusterRoleBinding exists
kubectl get clusterrolebinding prometheus-external

# Check it references the correct ServiceAccount
kubectl get clusterrolebinding prometheus-external -o yaml

# If missing, reapply:
kubectl apply -f flux/apps/prometheus-sa/clusterrolebinding-prometheus.yaml
```

### Error: "Secret 'prometheus-external-token' not found"

**Cause:** Secret not created or wrong namespace

**Fix:**
```bash
# Check if secret exists
kubectl get secret -n monitoring

# If missing, apply it:
kubectl apply -f flux/apps/prometheus-sa/secret-prometheus-token.yaml

# Wait ~10 seconds for Kubernetes to populate the token
kubectl get secret prometheus-external-token -n monitoring -o yaml
```

### Token file has wrong permissions

**Cause:** File created manually without proper permissions

**Fix:**
```bash
sudo chown prometheus:prometheus /var/lib/prometheus/k8s-token
sudo chmod 600 /var/lib/prometheus/k8s-token
sudo systemctl restart prometheus
```

### Prometheus doesn't reload after config change

**Fix:**
```bash
# Prometheus should auto-reload with enableReload = true
# If not, manually reload:
sudo systemctl reload prometheus

# Or check if lifecycle API is enabled:
curl -X POST http://localhost:9090/-/reload

# Check Prometheus logs for errors:
journalctl -u prometheus -n 50
```

---

## Alternative: Client Certificate Authentication

If you prefer client certificates over bearer tokens:

1. Extract client cert and key from kubeconfig:
   ```bash
   kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > /var/lib/prometheus/client.crt
   kubectl config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > /var/lib/prometheus/client.key
   kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /var/lib/prometheus/ca.crt
   ```

2. Update Prometheus scrape config:
   ```nix
   tls_config = {
     cert_file = "/var/lib/prometheus/client.crt";
     key_file = "/var/lib/prometheus/client.key";
     ca_file = "/var/lib/prometheus/ca.crt";
   };
   # Remove authorization block
   ```

**Note:** Bearer token approach is simpler and follows Kubernetes best practices.

---

## References

- [Kubernetes ServiceAccount Tokens](https://kubernetes.io/docs/concepts/configuration/secret/#service-account-token-secrets)
- [Prometheus Kubernetes SD Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)
- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Talos Kubernetes](https://www.talos.dev/)

---

**Status:** ✅ Configuration complete
**Next Steps:** Deploy and verify authentication works
