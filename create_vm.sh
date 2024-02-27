#!/bin/bash
VMNAME="$1"
VMFOLDER="$(pwd)/vm"
VMIMAGESFOLDER="$VMFOLDER/images"

# Error handling function
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Check if VM name is provided
if [ -z "$VMNAME" ]; then
    echo "Usage: $0 <VM_NAME>"
    exit 1
fi

# Install necessary packages if not already installed
#if ! command -v virt-install &>/dev/null; then
#    sudo apt update
#    sudo apt install -y virtinst
#    sudo apt install libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager -y
#fi

# Create folder if not exists and assign user:group
if [ ! -d "$VMFOLDER" ]; then
    # Create the folder if it doesn't exist
    mkdir -p "$VMFOLDER"
    chown libvirt-qemu:kvm $VMFOLDER
    echo "Folder created successfully at $VMFOLDER"
else
    echo "Folder already exists at $VMFOLDER"
fi

# Create folder if not exists and assign user:group
if [ ! -d "$VMIMAGESFOLDER" ]; then
    # Create the folder if it doesn't exist
    mkdir -p "$VMIMAGESFOLDER"
    chown libvirt-qemu:kvm $VMIMAGESFOLDER
    echo "Folder created successfully at $VMIMAGESFOLDER"
else
    echo "Folder already exists at $VMIMAGESFOLDER"
fi

# Download Debian ISO if not available
if [ ! -f $VMIMAGESFOLDER/Debian.iso ]; then
    wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso -O $VMIMAGESFOLDER/Debian.iso || handle_error "Failed to download Debian ISO"
fi

# Download Guest Additions ISO if not available
#if [ ! -f $VMIMAGESFOLDER/VBoxGuestAdditions.iso ]; then
#    wget https://download.virtualbox.org/virtualbox/6.1.30/VBoxGuestAdditions_6.1.30.iso -O $VMIMAGESFOLDER/VBoxGuestAdditions.iso || handle_error "Failed to download Guest Additions ISO"
#fi

# Shutdown and Remove VM if already exists # TODO
# virsh suspend $VMNAME
# virsh shutdown $VMNAME
# virsh shutdown --domain VM_NAME
# virsh destroy $VMNAME
# virsh destroy --domain VM_NAME
# virsh undefine $VMNAME
# virsh undefine --domain $VMNAME
# virsh connect $VMNAME
# virsh uri
# systemctl start virtqemud.socket
# systemctl is-enabled virtqemud # Failed to get unit file state for virtqemud.service: No such file or directory
# systemctl status libvirtd
# virsh -c qemu:///system list
# virsh connect qemu:///session
# https://www.techotopia.com/index.php/Installing_a_KVM_Guest_OS_from_the_Command-line_(virt-install)
# -w NETWORK, --network=NETWORK bridge:BRIDGE
# --network=bridge:br0
# virsh console PTIDebian
# extra-args='console=tty0 console=ttyS0,115200n8 serial'
# --vnc

# Create VM using virt-install
virt-install \
    --name "$VMNAME" \
    --memory 2048 \
    --vcpus 1 \
    --disk size=50 \
    --cdrom "$VMIMAGESFOLDER/Debian.iso" \
    --location "$VMIMAGESFOLDER/Debian.iso" \
    --network default \
    --graphics none \
    --noautoconsole \
    --os-variant debian12 \
    --boot cdrom,hd \
    --extra-args 'console=ttyS0,115200n8 serial' \
    #--vnc \
    #--os-type linux \

# Start the VM once ready
# virsh start "$VMNAME" || handle_error "Failed to start $VMNAME VM"
virsh start "$VMNAME"

# Connect to VM
# virsh console PTI1
# virsh --connect qemu:///session start PTI1
# virt-manager --connect=qemu:///session