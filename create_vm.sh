#!/bin/bash
VMNAME="$1"

# Check if VM name is provided
if [ -z "$VMNAME" ]; then
    echo "Usage: $0 <VM_NAME>"
    exit 1
fi

# Error handling function
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Check if debian.iso exist, then download if not
if [ ! -f ./debian.iso ]; then
    wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso -O debian.iso
fi
# Check if Guest Additions ISO exists, then download if not
if [ ! -f ./VBoxGuestAdditions.iso ]; then
    sudo wget https://download.virtualbox.org/virtualbox/6.1.30/VBoxGuestAdditions_6.1.30.iso -O VBoxGuestAdditions.iso
fi

# Create VM
VBoxManage createvm --name $VMNAME --ostype "Debian_64" --register --basefolder `pwd`

# Enable I/O APIC support
VBoxManage modifyvm $VMNAME --ioapic on

# Set memory
VBoxManage modifyvm $VMNAME --memory 2048 --vram 128

# Create Disk
VBoxManage createhd --filename `pwd`/$VMNAME/$VMNAME_DISK.vdi --size 50000 --format VDI
VBoxManage storagectl $VMNAME --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach $VMNAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium  `pwd`/$VMNAME/$VMNAME_DISK.vdi
# Mount Debian ISO
VBoxManage storagectl $VMNAME --name "IDE Controller" --add ide --controller PIIX4
VBoxManage storageattach $VMNAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium `pwd`/debian.iso
# Mount Guest Additions ISO
VBoxManage storageattach $VMNAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium `pwd`/VBoxGuestAdditions.iso
# Set boot priority
VBoxManage modifyvm $VMNAME --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Enable RDP (Remote Desktop Protocol)
VBoxManage modifyvm $VMNAME --vrde on
VBoxManage modifyvm $VMNAME --vrdemulticon on --vrdeport 3389

# Add network card
VBoxManage modifyvm $VMNAME --nic1 nat
# Enable services and port forwardings
VBoxManage modifyvm $VMNAME --natpf1 "ssh,tcp,,3022,,22"

# Start the VM once ready
VBoxHeadless --startvm $VMNAME