# STEP 1
# first make sure server resources are allocated per need. RAM, etc. 
# make sure ports are open in security group. For master-node: ports 22, 6443, 2379-2380 & 10250-10252
# worker node ports: 22, 10250, 30000 - 32767
# For weave-net to work, open port 6783-6784 on both security groups

sudo apt-get update -y
sudo apt-get upgrade -y

# STEP 2
# disable swap

sudo swapoff -a

# enter private ip and hostname of master and workers into /etc/hosts
# example below
# 172.31.85.94    master
# 172.31.91.4     worker1
# 172.31.83.250   worker2

# STEP 3
# install container runtime pre-reqistic

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# STEP 4
# Install containerd

sudo apt-get update -y
sudo apt-get install containerd -y

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd


# STEP 5
# install pre-req for kubeadm, kubelet and kubectl on all nodes.

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# STEP 6
# Install kubelet, kubeadm & kubectl on all, if specific version needed, this is where we can specify version.
# apt-cache madison kubeadm 
# above command provides all available kubeadm versions and we can select the one.

sudo apt-get update -y
sudo apt-get install -y kubelet=1.21.0-00 kubeadm=1.21.0-00 kubectl=1.21.0-00
sudo apt-mark hold kubelet kubeadm kubectl

sudo apt-get update -y

# STEP 1 TO 6 OR UPTO THIS POINT SHOLD BE DONE ON ALL NODES AND MASTERS.

# STEP 7
# initialize kubeadm on master only. this creates reqired certs and all components.

sudo kubeadm init

# once init completes, we can see nodes by running sudo kubectl get node --kubeconfig /etc/kubernetes/admin.conf
# but passing config file everytime and running as root is not convenient.

mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

kubectl get nodes -o wide



# STEP 8
# POD NETWORKING
# Setting up Pod Networking, we will use weave-net plugin here. 
# https://www.weave.works/docs/net/latest/kubernetes/kube-addon/

# download yaml file from here and modify IP range, wget "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')" -O weave.yaml
# weave by default assigns pod network on 10. range but we can manually modify yaml file to allocate different range as below. This should be under daemon-set in this file.
# command:
  #              - /home/weave/launch.sh
  #              - --ipalloc-range=100.32.0.0/12



# verify pods are getting defined ip.


# STEP 9
# add cluster nodes to the cluster

# for this first create join token on master

# kubeadm token create --print-join-command

# above will create something like this: kubeadm join 172.31.85.192:6443 --token c78c2h.8ljxso9olaaag9ns --discovery-token-ca-cert-hash sha256:c7bd27047637ffc9007a96afb958d406ce5e91bc5f766a8c4253d6d205207501
# run above join command with sudo






