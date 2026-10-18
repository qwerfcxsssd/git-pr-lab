#!/usr/bin/env bash
# Создание VM вручную на Linux-хосте с KVM (/dev/kvm должен существовать).
# Требуется: qemu-kvm, libvirt, virtinst, cloud-image-utils.
set -euo pipefail

VM=lab-vm
IMG=noble-server-cloudimg-amd64.img
DISK=/var/lib/libvirt/images/${VM}.qcow2

test -e /dev/kvm || { echo "KVM недоступен"; exit 1; }

wget -nc https://cloud-images.ubuntu.com/noble/current/${IMG}
sudo qemu-img create -f qcow2 -F qcow2 -b "$(pwd)/${IMG}" "${DISK}" 20G

sudo virt-install \
  --name "${VM}" \
  --memory 4096 \
  --vcpus 2 \
  --disk "${DISK}",bus=virtio \
  --import \
  --os-variant ubuntu24.04 \
  --network network=default,model=virtio \
  --cloud-init user-data=kvm/user-data.yaml \
  --graphics none \
  --noautoconsole

sleep 30
sudo virsh domifaddr "${VM}"
