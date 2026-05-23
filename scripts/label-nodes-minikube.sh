#!/usr/bin/env bash
set -euo pipefail

NODES=($(kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort))
COUNT=${#NODES[@]}

if [ "$COUNT" -lt 2 ]; then
  echo "Нужно минимум 2 узла. Запустите: minikube start --nodes 3 --cpus=4 --memory=10240"
  exit 1
fi

SYSTEM_NODE="${NODES[0]}"
APP_NODE="${NODES[1]}"
FAST_NODE="${NODES[2]:-$APP_NODE}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/label-nodes.sh" "$SYSTEM_NODE" "$APP_NODE" "$FAST_NODE"
