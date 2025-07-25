#!/bin/bash
################# 1.32.1  ################
# The code herein is: mudasir.s.tech@gmail.com, 2025
#
# This Copyright is retained for the purpose of protecting free
# redistribution of source.
#
#     email:  mudasir.s.tech@gmail.com

# Verify this version is what your cluster is currently at
export VER=1.32.1-1.1

# Check to see if the script has been run before. Exit out if so.
FILE=/k8scp_run
if [ -f "$FILE" ]; then
    echo "WARNING!"
    echo "$FILE exists. Script has already been. Do not run on control plane."
    echo "This should be run on the worker node."
    echo
    exit 1
else
    echo "$FILE does not exist. Running  script"
fi


# Create a file when this script is started to keep it from running
# on the control plane node.
sudo touch /k8scp_run

# Update the system
sudo apt update ; sudo apt upgrade -y

# Install necessary software
sudo apt install curl apt-transport-https vim git wget gnupg2 software-properties-common apt-transport-https ca-certi                                                                                                                        ficates socat -y

# Add repo for Kubernetes
sudo mkdir -m 755 -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernet                                                                                                                        es-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" |                                                                                                                         sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install the Kubernetes software, and lock the version
sudo apt update
sudo apt -y install kubelet=$VER kubeadm=$VER kubectl=$VER
sudo apt-mark hold kubelet kubeadm kubectl

# Ensure Kubelet is running
sudo systemctl enable --now kubelet

# Disable swap just in case
sudo swapoff -a

# Ensure Kernel has modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Update networking to allow traffic
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Configure containerd settings

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo sysctl --system

# Install the containerd software
# Install the containerd software
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/u                                                                                                                        buntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install containerd.io -y


# Configure containerd and restart
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd


# Ready to continue
sleep 3
echo
echo
echo '***************************'
echo
echo "Continue to the next step"
echo
echo "Use sudo and copy over or build a new"
echo "kubeadm join command from control plane."
echo
echo "Don't forget to edit /etc/hosts to use the alias IP"
echo
echo '***************************'
echo
echo
