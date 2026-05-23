#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="${ROOT_DIR}/k8s/infra/csi-s3-driver.yaml"

echo "Удаляем старую установку, если была..."
kubectl delete daemonset csi-s3 -n kube-system --ignore-not-found
kubectl delete clusterrolebinding csi-s3 --ignore-not-found
kubectl delete clusterrole csi-s3 --ignore-not-found
kubectl delete serviceaccount csi-s3 -n kube-system --ignore-not-found

if command -v minikube >/dev/null 2>&1 && minikube status >/dev/null 2>&1; then
  minikube image pull registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.12.0 || true
  minikube image pull ctrox/csi-s3:v1.2.0-rc.2 || true
fi

echo "Устанавливаем CSI S3..."
kubectl apply -f "$MANIFEST"

echo "Ждём pod'ы csi-s3 (до 5 минут)..."
if kubectl -n kube-system wait --for=condition=ready pod -l app=csi-s3 --timeout=300s; then
  echo "CSI S3 установлен."
else
  kubectl -n kube-system get pods -l app=csi-s3
  kubectl -n kube-system describe pod -l app=csi-s3 | grep -E "Failed|Error|Pulling|Image:" | tail -30
  exit 1
fi

kubectl -n kube-system get pods -l app=csi-s3
