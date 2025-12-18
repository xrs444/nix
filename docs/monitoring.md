# Monitoring Setup Guide

## Overview

Your infrastructure now has Prometheus + Grafana monitoring configured with:

- **xsvr1**: Monitoring server (Prometheus + Grafana)
- **xsvr2, xsvr3**: Monitoring clients (exporters only)

## Deployment

### Initial Deployment

1. **Commit and push changes:**

   ```bash
   git add -A
   git commit -m "Add Prometheus + Grafana monitoring"
   git push
   ```

2. **Deploy to xsvr1 (monitoring server):**

   ```bash
   # SSH to xsvr1
   ssh thomas-local@xsvr1

   # Pull latest config and rebuild
   cd /etc/nixos  # or wherever your config lives
   sudo nixos-rebuild switch --flake .#xsvr1
   ```

3. **Deploy to xsvr2 and xsvr3 (monitoring clients):**

   ```bash
   # For xsvr2
   ssh thomas-local@xsvr2
   sudo nixos-rebuild switch --flake .#xsvr2

   # For xsvr3
   ssh thomas-local@xsvr3
   sudo nixos-rebuild switch --flake .#xsvr3
   ```

### Access Monitoring

After deployment, access via Tailscale network:

- **Prometheus**: <http://xsvr1:9090>
- **Grafana**: <http://xsvr1:3000>
  - Default login: `admin` / `admin`
  - Change password on first login

## Verification

### Check Services are Running

On xsvr1:

```bash
# Check Prometheus
sudo systemctl status prometheus

# Check Grafana
sudo systemctl status grafana

# Check node exporter
sudo systemctl status prometheus-node-exporter

# Check ZFS exporter (xsvr1 has ZFS)
sudo systemctl status prometheus-zfs-exporter
```

On xsvr2/xsvr3:

```bash
# Check node exporter
sudo systemctl status prometheus-node-exporter

# Check ZFS exporter (xsvr2 only)
sudo systemctl status prometheus-zfs-exporter
```

### Test Endpoints

```bash
# From xsvr1, check local exporters
curl http://localhost:9100/metrics  # node_exporter
curl http://localhost:9134/metrics  # zfs_exporter (on xsvr1/xsvr2)

# Check remote exporters
curl http://xsvr2:9100/metrics
curl http://xsvr3:9100/metrics
```

### Verify Prometheus Targets

1. Open <http://xsvr1:9090>
2. Navigate to Status → Targets
3. Verify all targets are "UP":
   - prometheus (localhost:9090)
   - node exporters (xsvr1:9100, xsvr2:9100, xsvr3:9100)
   - zfs exporters (xsvr1:9134, xsvr2:9134)

## Using Grafana

### First Steps

1. **Access Grafana**: <http://xsvr1:3000>
2. **Login**: admin/admin (change password)
3. **Verify Datasource**:
   - Settings → Data Sources
   - "Prometheus" should already be configured

### Import Dashboards

Recommended community dashboards:

1. **Node Exporter Full** (ID: 1860)
   - Comprehensive system metrics
   - Dashboards → Import → Enter ID: 1860

2. **ZFS Dashboard** (ID: 15362)
   - ZFS pool health and performance
   - Dashboards → Import → Enter ID: 15362

To import:

- Go to Dashboards → Import
- Enter dashboard ID or upload JSON
- Select "Prometheus" datasource
- Click Import

## Security Notes

- **Firewall**: Services only accessible via Tailscale interface
- **Password**: Change Grafana admin password immediately
- **TODO**: Implement secrets management for Grafana password

## Kubernetes Monitoring

### K8s Overview

Your Kubernetes cluster is now monitored by Prometheus on xsvr1. The setup includes:

- **kube-state-metrics**: Cluster-level metrics (deployments, pods, services, etc.)
- Metrics accessible via Prometheus and Grafana

### Prerequisites

1. **Network Connectivity**: xsvr1 must be able to reach your K8s cluster
2. **Service Discovery**: Either:
   - DNS resolution for `*.svc.cluster.local` from xsvr1
   - Direct IP access to K8s services
   - Ingress/LoadBalancer exposing metrics endpoints

### Step 1: Deploy kube-state-metrics to Kubernetes

Create the following files in `flux/apps/kube-state-metrics/`:

#### `namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
```

#### `deployment.yaml`

See full content below - includes ServiceAccount, ClusterRole, ClusterRoleBinding, and Deployment

#### `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    app.kubernetes.io/name: kube-state-metrics
spec:
  type: ClusterIP
  ports:
  - name: metrics
    port: 8080
    targetPort: metrics
    protocol: TCP
  selector:
    app.kubernetes.io/name: kube-state-metrics
```

#### `kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: monitoring
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
```

### Step 2: Expose kube-state-metrics to xsvr1

Choose one approach:

**Option A: NodePort Service** (Easiest)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics-external
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - name: metrics
    port: 8080
    targetPort: 8080
    nodePort: 30080  # Choose a port in range 30000-32767
  selector:
    app.kubernetes.io/name: kube-state-metrics
```

Then update Prometheus config in `prometheus.nix`:

```nix
k8sTargets = {
  kubeStateMetrics = "your-k8s-node-ip:30080";
};
```

**Option B: LoadBalancer/Ingress** (If you have MetalLB or similar)

Create an ingress or LoadBalancer service and use that endpoint.

**Option C: Tailscale/VPN** (If K8s nodes are on Tailscale)

Use the Tailscale hostname directly:

```nix
k8sTargets = {
  kubeStateMetrics = "k8s-node.tailnet:8080";
};
```

### Step 3: Deploy to Kubernetes

```bash
# Add kube-state-metrics to apps kustomization
cd flux/apps
# Edit kustomization.yaml to include kube-state-metrics

# Commit and push
git add -A
git commit -m "Add kube-state-metrics for Prometheus monitoring"
git push

# Flux will automatically deploy, or force reconcile:
flux reconcile kustomization apps
```

### Step 4: Update Prometheus on xsvr1

The Prometheus configuration has already been updated with K8s scrape configs. You just need to:

1. **Update the target address** in `nix/modules/services/monitoring/prometheus.nix`:

   - Replace the placeholder in `k8sTargets.kubeStateMetrics`
   - Use the actual IP/hostname based on your chosen exposure method

2. **Deploy to xsvr1**:

```bash
# From your development machine
cd nix
git add -A
git commit -m "Add Kubernetes monitoring to Prometheus"
git push

# SSH to xsvr1
ssh thomas-local@xsvr1
cd /path/to/nix/config
sudo nixos-rebuild switch --flake .#xsvr1
```

### Step 5: Verify Kubernetes Monitoring

1. **Check Prometheus targets**: <http://xsvr1:9090/targets>
   - Look for `kube-state-metrics` job
   - Should show status "UP"

2. **Query K8s metrics** in Prometheus:

   ```promql
   # Number of pods
   kube_pod_info

   # Deployments
   kube_deployment_status_replicas

   # Node status
   kube_node_info
   ```

3. **Import Grafana dashboards**:
   - Dashboard ID 13332: "Kubernetes Cluster Monitoring"
   - Dashboard ID 15760: "Kubernetes Views - Global"

### Troubleshooting

**Issue**: Prometheus can't reach kube-state-metrics

- Check network connectivity: `ping` or `curl` from xsvr1
- Verify K8s service is running: `kubectl get svc -n monitoring`
- Check firewall rules on K8s nodes

**Issue**: Metrics not showing up

- Verify kube-state-metrics pod is running: `kubectl get pods -n monitoring`
- Check pod logs: `kubectl logs -n monitoring deployment/kube-state-metrics`
- Test endpoint directly: `curl http://NODE_IP:30080/metrics`

**Issue**: DNS resolution fails

- If using cluster.local DNS, ensure xsvr1 can resolve K8s DNS
- Alternative: Use NodePort with direct IP instead

### Additional K8s Monitoring (Optional)

To get complete K8s monitoring, consider adding:

1. **cAdvisor metrics** (container resource usage):

   - Already exposed by kubelet on `/metrics/cadvisor`
   - Add scrape config for kubelet endpoints

2. **API Server metrics**:

   ```nix
   {
     job_name = "kube-apiserver";
     static_configs = [{
       targets = [ "k8s-api-server:6443" ];
     }];
     scheme = "https";
     tls_config = {
       # Configure TLS if needed
     };
   }
   ```

3. **Node metrics from kubelet**:

   - Scrape `/metrics` endpoint on each node's kubelet (port 10250)

## Next Steps

1. **Add Alerting**:
   - Configure alertmanager in `prometheus.nix`
   - Add alert rules for critical metrics (K8s pods down, high memory, etc.)

2. **Dashboard Development**:
   - Create custom dashboards for your infrastructure
   - Consider provisioning dashboards via Nix config
   - Import community K8s dashboards

3. **Complete K8s Monitoring**:
   - Add kubelet/cAdvisor scrape configs
   - Monitor K8s API server
   - Add node-exporter DaemonSet to K8s for node metrics

4. **Additional Exporters**:
   - `smartmon_exporter`: SMART disk health
   - `systemd_exporter`: Detailed systemd metrics
   - `blackbox_exporter`: Endpoint availability checks

## General Troubleshooting

### Prometheus Not Scraping Targets

Check firewall rules on client hosts:

```bash
sudo nft list ruleset | grep 9100
```

Verify Tailscale connectivity:

```bash
tailscale status
ping xsvr2
```

### Grafana Can't Connect to Prometheus

```bash
# From xsvr1
curl http://localhost:9090/api/v1/query?query=up

# Check Grafana logs
sudo journalctl -u grafana -n 100
```

### Missing ZFS Metrics

Verify ZFS pools are imported:

```bash
zpool list
zpool status
```

Check ZFS exporter is running:

```bash
sudo systemctl status prometheus-zfs-exporter
curl http://localhost:9134/metrics | grep zfs
```

## Configuration Files

- Module: `modules/services/monitoring/`
- Roles: `flake.nix` (xsvr1, xsvr2, xsvr3)
- Documentation: `modules/services/monitoring/readme-doc.md`
