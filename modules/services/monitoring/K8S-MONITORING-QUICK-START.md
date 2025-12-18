# Quick Start: Add K8s Monitoring to Prometheus

## What Was Done

1. ✅ Created K8s manifests in `flux/apps/kube-state-metrics/`
2. ✅ Added kube-state-metrics to apps kustomization
3. ✅ Updated Prometheus config in `nix/modules/services/monitoring/prometheus.nix`
4. ✅ Created documentation in `nix/docs/kubernetes-monitoring-guide.md`

## What You Need to Do

### Step 1: Find Your K8s Node IP

```bash
kubectl get nodes -o wide
# Note the INTERNAL-IP of any node
```

### Step 2: Update Prometheus Target

Edit: `nix/modules/services/monitoring/prometheus.nix`

Find line ~39 and replace the placeholder:

```nix
k8sTargets = {
  kubeStateMetrics = "YOUR_K8S_NODE_IP:30080";  # <-- Update this
};
```

Replace `YOUR_K8S_NODE_IP` with the actual IP from Step 1.

### Step 3: Deploy to K8s

```bash
cd flux
git add -A
git commit -m "Add kube-state-metrics for Prometheus monitoring"
git push

# Wait for Flux auto-sync or trigger manually:
flux reconcile kustomization apps --with-source
```

### Step 4: Deploy to xsvr1

```bash
cd nix
git add -A
git commit -m "Add K8s monitoring to Prometheus"
git push

# SSH to xsvr1
ssh thomas-local@xsvr1
cd /etc/nixos  # or wherever your config lives
sudo nixos-rebuild switch --flake .#xsvr1
```

### Step 5: Verify

1. **Check K8s is running**:
```bash
kubectl get pods -n monitoring
# Should see kube-state-metrics pod in Running state

kubectl get svc -n monitoring
# Should see services including kube-state-metrics-nodeport
```

2. **Test metrics endpoint**:
```bash
curl http://YOUR_K8S_NODE_IP:30080/metrics | head -n 20
# Should see Prometheus metrics
```

3. **Check Prometheus** (from browser):
   - Go to: http://xsvr1:9090/targets
   - Look for job: `kube-state-metrics`
   - Status should be: **UP** (green)

4. **Query K8s metrics in Prometheus**:
   - Go to: http://xsvr1:9090/graph
   - Try queries:
     ```
     kube_pod_info
     kube_deployment_status_replicas
     kube_node_status_condition
     ```

5. **View in Grafana**:
   - Go to: http://xsvr1:3000
   - Import dashboard: 13332 (Kubernetes Cluster Monitoring)

## Troubleshooting

**Q: Prometheus shows target as DOWN**

A: Check connectivity from xsvr1:
```bash
ssh thomas-local@xsvr1
curl http://YOUR_K8S_NODE_IP:30080/metrics
```

**Q: K8s pod won't start**

A: Check logs:
```bash
kubectl logs -n monitoring deployment/kube-state-metrics
kubectl describe pod -n monitoring -l app.kubernetes.io/name=kube-state-metrics
```

**Q: Can't reach NodePort from xsvr1**

A: Check firewall rules on K8s nodes (NodePort 30080 must be accessible)

## Files Created

- `flux/apps/kube-state-metrics/namespace.yaml`
- `flux/apps/kube-state-metrics/deployment.yaml`
- `flux/apps/kube-state-metrics/service.yaml`
- `flux/apps/kube-state-metrics/service-nodeport.yaml`
- `flux/apps/kube-state-metrics/kustomization.yaml`
- `nix/docs/kubernetes-monitoring-guide.md`

## Next Steps

- Add alerting rules for K8s (pod restarts, node down, etc.)
- Import additional Grafana dashboards
- Consider adding kubelet metrics for container-level monitoring
- Set up log aggregation (Loki) for K8s logs
