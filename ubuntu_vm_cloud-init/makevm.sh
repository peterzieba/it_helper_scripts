#!/bin/sh
set -e

#apt install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon cloud-image-utils mtools -y
#mkdir -p /vm-files/INSTALL
#wget -P /vm-files/INSTALL https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img
#exit 2

echo "This script will create an Ubuntu 22.04.3 Server virtual machine."
read -p "Enter the name of the VM to create: " vmname
read -p "Enter the hostname you would like to use: " vmhostname
read -p "Enter the number of GB you would like the disk to have (i.e. 20G): " vmdisksize

if [ -f "/vm-files/${vmname}" ] || [ -f "/vm-files/${vmname}".yaml ] || [ -f "/vm-files/${vmname}".tmp ] || [ -f "/vm-files/${vmname}".init ] || [ -f "/vm-files/${vmname}".iso ]; then
    echo "${vmname} appears to already exist. Exiting."
    exit 1
fi

cp /vm-files/INSTALL/jammy-server-cloudimg-amd64-disk-kvm.img /vm-files/${vmname}.tmp
qemu-img resize /vm-files/${vmname}.tmp ${vmdisksize}
qemu-img convert /vm-files/${vmname}.tmp /vm-files/${vmname}

cat << EOF > /vm-files/${vmname}.yaml
#cloud-config
hostname: ${vmhostname}
manage_etc_hosts: false
ssh_pwauth: true
password: newpass!
disable_root: false
packages:
  - mc
EOF

echo "Running cloud-localds to generate a cloudinit image."
#cloud-localds ${vmname}.iso ${vmname}.yaml
cloud-localds -v -f vfat /vm-files/${vmname}.init /vm-files/${vmname}.yaml --network-config=/vm-files/net-dhcp-noIPv6.yaml #We're not making an .iso because apparently there's some horrible bug where the .iso isn't seen but a vfat does work.

echo "Checking cloud-init .yaml syntax"
yamllint -d "{extends: relaxed, rules: {line-length: {max: 220}}}" /vm-files/${vmname}.yaml #Lets not be so hasty about long lines being errors.
read -p "Press Enter to continue" anykey

echo "Running virt-install"
virt-install --name ${vmname} --memory 2048 --disk /vm-files/${vmname},device=disk,bus=virtio --disk /vm-files/${vmname}.init,device=disk,bus=virtio --os-variant ubuntu22.04 --virt-type kvm --graphics none --network bridge=br0 --import

