# Kubernetes Monitoring Setup for Prometheus

## Quick Start

This guide shows you how to add your Kubernetes cluster to be monitored by Prometheus on xsvr1.

## Architecture

```
xsvr1 (Prometheus) -----> K8s Cluster (kube-state-metrics)
                          |
                          +---> Exposes metrics on port 8080
                          +---> Provides cluster-level metrics
```

## Step 1: Create Kubernetes Manifests

Create these files in `flux/apps/kube-state-metrics/`:

### File: deployment.yaml

Save the complete deployment manifest (provided separately due to length).
This includes: ServiceAccount, ClusterRole, ClusterRoleBinding, and Deployment.

### File: service.yaml

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

### File: service-nodeport.yaml (For external access)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics-nodeport
  namespace: monitoring
  labels:
    app.kubernetes.io/name: kube-state-metrics
spec:
  type: NodePort
  ports:
  - name: metrics
    port: 8080
    targetPort: 8080
    nodePort: 30080  # Access via any node IP:30080
    protocol: TCP
  selector:
    app.kubernetes.io/name: kube-state-metrics
```

## Step 2: Update Prometheus Configuration

Edit `nix/modules/services/monitoring/prometheus.nix`:

Find the `k8sTargets` section and update with your actual K8s node IP:

```nix
k8sTargets = {
  kubeStateMetrics = "YOUR_K8S_NODE_IP:30080";
  # Or if using Tailscale: "k8s-node-hostname:30080"
  # Or if using internal DNS: "node1.your.domain:30080"
};
```

## Step 3: Deploy

### Deploy to Kubernetes

```bash
cd flux/apps
# Ensure kube-state-metrics is listed in kustomization.yaml

git add -A
git commit -m "Add kube-state-metrics for monitoring"
git push

# Wait for Flux to reconcile or trigger manually
flux reconcile kustomization apps
```

### Update xsvr1

```bash
cd nix
git add -A
git commit -m "Add K8s monitoring to Prometheus"
git push

# SSH to xsvr1 and rebuild
ssh thomas-local@xsvr1
cd /etc/nixos  # or your config path
sudo nixos-rebuild switch --flake .#xsvr1
```

## Step 4: Verify

1. **Check K8s deployment**:
   ```bash
   kubectl get pods -n monitoring
   kubectl get svc -n monitoring
   ```

2. **Test metrics endpoint** (from xsvr1 or any machine that can reach K8s):
   ```bash
   curl http://YOUR_K8S_NODE_IP:30080/metrics
   ```

3. **Check Prometheus targets**: Visit `http://xsvr1:9090/targets`
   - Look for job `kube-state-metrics`
   - Status should be "UP"

4. **Query metrics in Prometheus**:
   ```promql
   kube_pod_info
   kube_deployment_status_replicas
   kube_node_info
   ```

## Grafana Dashboards

Import these community dashboards for K8s monitoring:

1. **Kubernetes Cluster Monitoring** (ID: 13332)
   - Comprehensive cluster overview
   - Resource usage, pod status, deployments

2. **Kubernetes Views - Global** (ID: 15760)
   - Global cluster view
   - Namespace-level breakdown

3. **Kubernetes Views - Pods** (ID: 15761)
   - Detailed pod metrics
   - Container resource usage

To import:
1. Go to Grafana (http://xsvr1:3000)
2. Dashboards → Import
3. Enter dashboard ID
4. Select "Prometheus" as datasource
5. Click Import

## Troubleshooting

### Prometheus shows target as DOWN

1. **Check network connectivity from xsvr1**:
   ```bash
   ssh thomas-local@xsvr1
   curl http://YOUR_K8S_NODE_IP:30080/metrics
   ```

2. **Verify K8s service is accessible**:
   ```bash
   # From any K8s node
   curl http://localhost:30080/metrics
   ```

3. **Check kube-state-metrics pod**:
   ```bash
   kubectl logs -n monitoring deployment/kube-state-metrics
   kubectl describe pod -n monitoring -l app.kubernetes.io/name=kube-state-metrics
   ```

### No metrics appearing

1. **Verify RBAC permissions**:
   ```bash
   kubectl auth can-i list pods --as=system:serviceaccount:monitoring:kube-state-metrics
   ```

2. **Check kube-state-metrics is scraping**:
   ```bash
   kubectl port-forward -n monitoring svc/kube-state-metrics 8080:8080
   curl http://localhost:8080/metrics | grep kube_pod_info
   ```

### Firewall issues

If using Talos or other hardened K8s:
- Ensure NodePort range (30000-32767) is allowed through firewall
- Check if your CNI has network policies blocking external access

## Next Steps

### Add More K8s Metrics

1. **Deploy node-exporter as DaemonSet** for per-node system metrics
2. **Scrape kubelet metrics** for container-level resource usage
3. **Monitor K8s API server** for control plane health

### Set Up Alerting

Add alert rules in `prometheus.nix`:

```nix
rules = [
  {
    alert = "KubernetesPodCrashLooping";
    expr = "rate(kube_pod_container_status_restarts_total[15m]) > 0";
    for = "5m";
    labels = {
      severity = "warning";
    };
    annotations = {
      summary = "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping";
    };
  }
];
```

## Reference: Finding Your K8s Node IP

```bash
# Get node IPs
kubectl get nodes -o wide

# Get node IP for specific node
kubectl get node NODE_NAME -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'

# If using Tailscale
tailscale status | grep k8s
```

## Security Considerations

- kube-state-metrics runs read-only (list/watch permissions only)
- Metrics exposed on NodePort - ensure firewall rules are appropriate
- Consider using mutual TLS for production setups
- No sensitive data (secrets) is exposed by default

