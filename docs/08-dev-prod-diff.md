# Отличия окружений dev и prod

| Параметр | dev (`messager-dev`) | prod (`messager-prod`) |
|----------|----------------------|------------------------|
| Namespace | `messager-dev` | `messager-prod` |
| Реплики приложений | 1 | 2 (`frontend`, `bff`, `user-service`, `message-service`) |
| Теги образов | `latest` | `v1.0.0` |
| Ingress host | `dev.messager.local` | `messager.example.com` |
| Доступ к UI | `NodePort` 30080 + Ingress | Ingress |
| S3 bucket | `messager-uploads-dev` | `messager-uploads-prod` |
| PV uploads | `s3-pv-messager-dev-uploads` (10Gi) | `s3-pv-messager-prod-uploads` (20Gi) |
| CPU/RAM | пониженные limits | повышенные limits |
| nodeAffinity | из `base` (system/app + disk=fast) | из `base` (без ослабления) |

Общее для обоих overlay: MinIO, Postgres, миграции, CSI S3, Argo CD GitOps.
