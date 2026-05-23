# Отчёт по лабораторной работе. 

**Тема:** развёртывание микросервисного мессенджера в Kubernetes  

**Выполнила:** Бурцева М. А.

**Номер группы:** М8О-106БВ-25

---

## 1. Цель работы

Развернуть микросервисный мессенджер в Kubernetes, настроить хранение файлов через S3-совместимое хранилище, `nodeAffinity`, конфигурации `dev` и `prod` (Kustomize) и GitOps-деплой (Argo CD). Исходный код сервисов не изменялся.

---

## 2. Исходные данные

Приложение состоит из `frontend`, `bff`, `user-service`, `message-service`, `postgres`, Job миграций и MinIO. Использованы образы `mablinov2704/*` с Docker Hub. Техническое задание и примеры — в каталоге `docs/`.

---

## 3. Ход работы

### 3.1. Подготовка манифестов Kubernetes

В каталоге `k8s/base/` описаны общие ресурсы: Namespace, ConfigMap, Secret, Deployment для всех сервисов, Service, Job миграций (`goose`), MinIO, Ingress. SQL-миграции вынесены в `k8s/base/migrations/` и подключаются через `configMapGenerator`.

Далее оформлены overlay:

- `k8s/overlays/dev/` — namespace `messager-dev`, тег образов `latest`, по одной реплике, NodePort `30080` для доступа к frontend;
- `k8s/overlays/prod/` — namespace `messager-prod`, тег `v1.0.0`, две реплики прикладных сервисов, увеличенные ресурсы, host Ingress `messager.example.com`.

Отличия окружений зафиксированы в `docs/08-dev-prod-diff.md`. Сборку проверяла командами `kubectl kustomize` для обоих overlay.

### 3.2. Настройка nodeAffinity

По заданию узлы разделены на классы `workload=system` и `workload=app`, для части app-узлов добавлена метка `disk=fast`. В Deployment прописаны правила: `postgres`, `minio` и Job — только на `system`; `frontend`, `bff`, `user-service` — только на `app`; `message-service` — на `app` с предпочтением `disk=fast`.

Для разметки узлов использованы скрипты в `scripts/` (в том числе `label-nodes-minikube.sh` для кластера из трёх узлов Minikube).

### 3.3. Хранилище файлов и MinIO

Развёрнут MinIO, Job создания bucket, Secret для доступа к S3. В overlay **prod** для `message-service` настроены PersistentVolume, PVC и монтирование через CSI-драйвер `ch.ctrox.csi.s3-driver` (`k8s/infra/csi-s3-driver.yaml`).

При проверке на Minikube монтирование CSI для `message-service` переходило в длительный статус `ContainerCreating`. Для окружения **dev** в overlay добавлен patch с томом `emptyDir`, чтобы приложение стабильно запускалось локально; PV, PVC и MinIO в namespace `messager-dev` оставлены в манифестах. Обоснование — в `docs/09-minikube-dev-vs-prod-storage.md`.

### 3.4. Argo CD

В каталоге `argocd/` созданы `AppProject` и два `Application` (`messager-dev`, `messager-prod`) с путями к overlay, автосинхронизацией, `prune` и `selfHeal`.

### 3.5. Развёртывание и проверка в кластере

1. Поднят кластер Minikube (3 узла, включён addon `ingress`).
2. Размечены узлы; для `minikube-m03` дополнительно задана метка `workload=app` (наряду с `disk=fast`).
3. Установлен CSI S3 driver.
4. Выполнено развёртывание: `kubectl apply -k k8s/overlays/dev`.
5. После правки тома для `message-service` все pod'ы перешли в рабочие состояния.
6. Проведена функциональная проверка через веб-интерфейс (регистрация, сообщения, отправка изображения).

Доступ к UI получен через NodePort сервиса `frontend` (порт `30080`).

---

## 4. Результаты проверки

### 4.1. Метки узлов

```bash
kubectl get nodes -L workload,disk
```

```
NAME           STATUS   ROLES           AGE   VERSION   WORKLOAD   DISK
minikube       Ready    control-plane   35m   v1.35.1   system
minikube-m02   Ready    <none>          34m   v1.35.1   app
minikube-m03   Ready    <none>          34m   v1.35.1   app        fast
```

### 4.2. Состояние подов

```bash
kubectl -n messager-dev get pods -o wide
```

```
NAME                              READY   STATUS      RESTARTS      AGE     IP            NODE
bff-79b6d4fd6d-dgzms              1/1     Running     0             23m     10.244.2.2    minikube-m03
frontend-6dc67b44c-ffzzb          1/1     Running     0             23m     10.244.1.2    minikube-m02
message-service-795dd45d6-mc96b   1/1     Running     0             6m13s   10.244.2.5    minikube-m03
migrate-messages-xxn5d            0/1     Completed   0             23m     10.244.0.8    minikube
migrate-users-tzbbr               0/1     Completed   0             23m     10.244.0.9    minikube
minio-84cb44b8c-cqcxb             1/1     Running     0             23m     10.244.0.6    minikube
minio-create-bucket-kj9p6         0/1     Completed   0             20m     10.244.0.11   minikube
postgres-6c77674bf6-48hvc         1/1     Running     0             23m     10.244.0.7    minikube
user-service-68f9576c65-s6kl4     1/1     Running     3 (22m ago)   23m     10.244.2.3    minikube-m03
```

`postgres`, `minio` и Job — на узле `minikube` (`system`); прикладные сервисы — на `minikube-m02` и `minikube-m03` (`app`); `message-service` размещён на узле с меткой `disk=fast`.

### 4.3. Kustomize

```bash
kubectl kustomize k8s/overlays/dev > /dev/null && echo "dev OK"
kubectl kustomize k8s/overlays/prod > /dev/null && echo "prod OK"
```

```
dev OK
prod OK
```

### 4.4. Функциональная проверка

Проверены регистрация пользователей, обмен сообщениями и отправка изображения. Цепочка `frontend → bff → user-service / message-service` отрабатывает корректно.

---

## 5. Структура репозитория

```
k8s/base/
k8s/overlays/dev/
k8s/overlays/prod/
k8s/infra/
argocd/
scripts/
docs/
```

---

## 6. Вывод

В процессе работы подготовлены манифесты Kubernetes и Kustomize-overlay для окружений `dev` и `prod`, настроены `nodeAffinity`, MinIO и CSI S3 для production, манифесты Argo CD. На Minikube развёрнуто и проверено окружение `dev`; размещение pod'ов соответствует заданным правилам affinity, приложение работает в веб-интерфейсе.
