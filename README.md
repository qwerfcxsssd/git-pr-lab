# git-pr-lab

Учебный репозиторий: Git и GitHub workflow (лабораторная 1), Docker Compose, KVM и Ansible (лабораторная 2).

## Приложение

- `backend/`: Flask + gunicorn, отдаёт `GET /api/info` (сообщение, hostname контейнера, время).
- `frontend/`: nginx, раздаёт `index.html` и проксирует `/api/` на `backend:5000`.
- `compose.yaml`: оба сервиса, наружу опубликован только порт фронтенда `8080`.

Страница при загрузке делает `fetch('/api/info')` и показывает ответ бэкенда.

## Схема



## Запуск локально

```bash
docker compose up -d --build
curl http://localhost:8080/api/info
```

Адрес: http://localhost:8080

## Запуск в VM через Ansible

```bash
limactl create --name=lab-vm --vm-type=vz --network=vzNAT --cpus=2 --memory=4 --disk=20 \
  --set '.containerd.system=false | .containerd.user=false' template:ubuntu-24.04
limactl start lab-vm
ansible app -m ping
ansible-playbook ansible/playbook.yml
```

Адрес: http://192.168.64.2:8080

Playbook ставит Docker, Compose и buildx, копирует `backend/`, `frontend/`, `compose.yaml` в `/opt/git-pr-lab`, запускает Compose через `community.docker.docker_compose_v2` и проверяет `/api/info`. Образы пересобираются только если изменились файлы, поэтому повторный запуск завершается с `changed=0`.

## Проверка связи фронтенда с бэкендом

```bash
curl http://192.168.64.2:8080/api/info
```

Запрос идёт в nginx (frontend), тот проксирует его на backend. Ответ содержит hostname контейнера бэкенда. Ту же проверку выполняет последняя задача playbook.

## Диагностика KVM

- Ноутбук: macOS 26.5.2, Apple M1 Pro (arm64).
- `ls /dev/kvm` на macOS: нет такого файла. KVM есть только в ядре Linux.
- `sysctl kern.hv_support` = 1: доступен только Hypervisor.framework macOS.
- Внутри Linux VM: `/dev/kvm` отсутствует, `dmesg` пишет `kvm [1]: HYP mode not available`, `kvm-ok` сообщает `/dev/kvm does not exist`.
- Причина: вложенную виртуализацию на Apple Silicon поддерживают только чипы M3 и новее (macOS 15+), на M1 Pro гостю недоступен EL2.

Поэтому VM создана через Lima (Virtualization.framework). Для Linux-хоста с KVM подготовлен скрипт ручного создания VM `kvm/create-vm.sh` (`virt-install` + cloud-init `kvm/user-data.yaml`). После создания достаточно поменять `ansible_host` в `ansible/inventory.ini` на IP из `virsh domifaddr lab-vm` и запустить тот же playbook, проверка такая же: `curl http://<IP>:8080/api/info`.

## CI

- `ci.yml`: проверка Python и TruffleHog.
- `trivy.yml`: сборка образов из `compose.yaml` и сканирование Trivy (HIGH, CRITICAL).
