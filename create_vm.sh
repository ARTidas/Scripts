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

# Download Debian ISO if not available
if [ ! -f ./Debian.iso ]; then
    wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso -O Debian.iso || handle_error "Failed to download Debian ISO"
fi

# Download Guest Additions ISO if not available
if [ ! -f ./VBoxGuestAdditions.iso ]; then
    sudo wget https://download.virtualbox.org/virtualbox/6.1.30/VBoxGuestAdditions_6.1.30.iso -O VBoxGuestAdditions.iso || handle_error "Failed to download Guest Additions ISO"
fi

# Create VM
VBoxManage createvm --name "$VMNAME" --ostype "Debian_64" --register --basefolder "$(pwd)" || handle_error "Failed to create VM"

# Enable I/O APIC support
VBoxManage modifyvm "$VMNAME" --ioapic on || handle_error "Failed to enable I/O APIC"

# Set memory
VBoxManage modifyvm "$VMNAME" --memory 2048 --vram 128 || handle_error "Failed to set memory"

# Create Disk
VBoxManage createhd --filename "$(pwd)/$VMNAME/$VMNAME_DISK.vdi" --size 50000 --format VDI || handle_error "Failed to create disk"
VBoxManage storagectl "$VMNAME" --name "SATA Controller" --add sata --controller IntelAhci || handle_error "Failed to add SATA controller"
VBoxManage storageattach "$VMNAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$(pwd)/$VMNAME/$VMNAME_DISK.vdi" || handle_error "Failed to attach disk"

# Add IDE Controller
VBoxManage storagectl "$VMNAME" --name "IDE Controller" --add ide --controller PIIX4 || handle_error "Failed to add IDE controller"

# Mount Debian ISO
VBoxManage storageattach "$VMNAME" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$(pwd)/Debian.iso" --mtype readonly || handle_error "Failed to attach Debian ISO"

# Mount Guest Additions ISO
VBoxManage storageattach "$VMNAME" --storagectl "IDE Controller" --port 1 --device 1 --type dvddrive --medium "$(pwd)/VBoxGuestAdditions.iso" || handle_error "Failed to attach Guest Additions ISO"

# Set boot priority
VBoxManage modifyvm "$VMNAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none || handle_error "Failed to set boot priority"

# Enable RDP (Remote Desktop Protocol)
VBoxManage modifyvm "$VMNAME" --vrde on || handle_error "Failed to enable RDP"
VBoxManage modifyvm "$VMNAME" --vrdemulticon on --vrdeport 3389 || handle_error "Failed to configure RDP"

# Add network card and enable services
VBoxManage modifyvm "$VMNAME" --nic1 nat || handle_error "Failed to add network card"
VBoxManage modifyvm "$VMNAME" --natpf1 "ssh,tcp,,3022,,22" || handle_error "Failed to configure port forwarding"

# Start the VM once ready
VBoxHeadless --startvm "$VMNAME" || handle_error "Failed to start VM"
