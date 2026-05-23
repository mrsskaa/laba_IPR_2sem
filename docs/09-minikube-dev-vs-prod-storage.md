# Хранилище файлов: dev (Minikube) vs prod

## dev

Patch `k8s/overlays/dev/patches/message-service-emptydir.yaml` — том `emptyDir` для `/app/uploads`. На Minikube CSI S3 mount часто зависает в `ContainerCreating`.

В namespace остаются MinIO, PV, PVC, Secret для CSI — ресурсы видны в `kubectl get all,pvc,pv`.

## prod

`message-service` монтирует `message-uploads-pvc` через CSI (`ch.ctrox.csi.s3-driver`), bucket в MinIO — по ТЗ.

## Защита

- Локально: работающий UI (dev overlay).
- В Git: prod с CSI, Argo CD, Kustomize.
