#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <system-node> <app-node> [fast-app-node]"
  echo "Example: $0 minikube minikube-m02 minikube-m03"
  exit 1
fi

SYSTEM_NODE="$1"
APP_NODE="$2"
FAST_NODE="${3:-$APP_NODE}"

if [ "$SYSTEM_NODE" = "$APP_NODE" ]; then
  echo "Ошибка: system и app не могут быть на одном узле ($SYSTEM_NODE)."
  exit 1
fi

kubectl label node "$SYSTEM_NODE" workload=system --overwrite
kubectl label node "$APP_NODE" workload=app --overwrite
if [ "$FAST_NODE" != "$APP_NODE" ]; then
  kubectl label node "$FAST_NODE" workload=app --overwrite
fi
kubectl label node "$FAST_NODE" disk=fast --overwrite

kubectl get nodes -L workload,disk
