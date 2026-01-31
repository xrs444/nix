#!/usr/bin/env bash
# Summary: Extract Kubernetes ServiceAccount token for Prometheus external scraping
# This script extracts the bearer token from the prometheus-external ServiceAccount
# and saves it to /var/lib/prometheus/k8s-token for use by Prometheus scrape configs.

set -euo pipefail

# Configuration
NAMESPACE="monitoring"
SERVICE_ACCOUNT="prometheus-external"
SECRET_NAME="prometheus-external-token"
OUTPUT_FILE="/var/lib/prometheus/k8s-token"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found in PATH"
    echo "Please install kubectl or ensure it's in your PATH"
    exit 1
fi

# Check if kubeconfig exists
if [ ! -f "$KUBECONFIG" ]; then
    echo "Error: kubeconfig not found at $KUBECONFIG"
    echo "Please set KUBECONFIG environment variable or place config at ~/.kube/config"
    exit 1
fi

# Check if the secret exists
if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    echo "Error: Secret $SECRET_NAME not found in namespace $NAMESPACE"
    echo "Please ensure the Flux Kustomization 'prometheus-sa' has been applied"
    echo ""
    echo "To check: kubectl get secret -n $NAMESPACE"
    exit 1
fi

# Extract the token
echo "Extracting token from secret $SECRET_NAME..."
TOKEN=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.token}' | base64 -d)

if [ -z "$TOKEN" ]; then
    echo "Error: Token is empty. The secret may not be properly configured."
    exit 1
fi

# Create directory if it doesn't exist
sudo mkdir -p "$(dirname "$OUTPUT_FILE")"

# Save the token
echo "$TOKEN" | sudo tee "$OUTPUT_FILE" > /dev/null

# Set proper permissions (readable only by prometheus user and root)
sudo chown prometheus:prometheus "$OUTPUT_FILE" 2>/dev/null || sudo chown root:root "$OUTPUT_FILE"
sudo chmod 600 "$OUTPUT_FILE"

echo "✓ Token successfully saved to $OUTPUT_FILE"
echo "✓ Permissions set to 600"
echo ""
echo "The token is now ready for use by Prometheus."
echo "Prometheus will automatically use this token for Kubernetes API authentication."
echo ""
echo "To verify the token works, run:"
echo "  curl -k -H \"Authorization: Bearer \$(cat $OUTPUT_FILE)\" https://172.20.3.10:6443/metrics"
