#!/usr/bin/env bash
set -euo pipefail

if ! command -v minikube >/dev/null 2>&1; then
  echo "minikube не найден"
  exit 1
fi

for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo "--- $node ---"
  minikube ssh -n "$node" "sudo modprobe fuse 2>/dev/null || true; ls -l /dev/fuse" || true
done
