#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

chmod +x scripts/*.sh

./scripts/label-nodes-minikube.sh
./scripts/install-csi-s3.sh || true
kubectl apply -k k8s/overlays/dev

kubectl -n messager-dev get pods
echo "Сайт: minikube service frontend -n messager-dev --url"
