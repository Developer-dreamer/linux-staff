#!/bin/bash

delete_vm() {
    local vm_name=$1
    echo "Deleting VM $vm_name..."
    
    if ! multipass list | grep -q "$vm_name"; then
        echo "VM $vm_name does not exist"
        return
    fi
    
    multipass delete --purge "$vm_name"
    
    const_config=/home/serafym/.ssh/config

    if ! grep -q "$vm_name" "$const_config"; then
        return        
    fi

    # Use sed to delete one line before the match and the match plus three lines after
    sed -i -e "/Host $vm_name/{ 
        x; 
        1!{h;d}; 
        x; 
        N; N; N; 
        d; 
    }" "$const_config"
}

build_vm() {
    local vm_name=$1
    disk_size_default=5G
    ram_size_default=1G
    cpu_count_default=1
    
    echo "Building VM $vm_name..."
    multipass launch --name="$vm_name" --disk "$disk_size_default" --memory "$ram_size_default" --cpus "$cpu_count_default"

    if ! multipass list | grep -q "$vm_name"; then
        echo "Error occurred for $vm_name VM"
        return
    fi
}

configure_ip() {
    local vm_name=$1
    local ip_address=$(multipass info "$vm_name" | grep "IPv4" | awk '{print $2}')
    local const_config=/home/serafym/.ssh/config 

    echo "Configuring IP for $vm_name..."

    cat << EOF >> "$const_config"
Host $vm_name
    HostName $ip_address
    User ubuntu
EOF
    
    if ! grep -q "$vm_name" "$const_config"; then
        echo "Error occurred while writing to $const_config file"
        return
    fi
}

configure_ssh() {
    local vm_name=$1
    local ssh_key=$(cat /home/serafym/.ssh/id_ed25519.pub)

    multipass exec "$vm_name" -- bash -c 'mkdir -p ~/.ssh'
    echo "$ssh_key" | multipass exec "$vm_name" -- bash -c 'cat >> ~/.ssh/authorized_keys'
    multipass exec "$vm_name" -- bash -c 'chmod 600 ~/.ssh/authorized_keys'
}

read -p "Enter the VM name: " vm_name

delete_vm "$vm_name"
build_vm "$vm_name"
configure_ip "$vm_name"
configure_ssh "$vm_name"

