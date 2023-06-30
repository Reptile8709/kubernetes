export DEBIAN_FRONTEND=noninteractive

echo "[TASK 1] show whoami"
whoami

echo "[TASK 2] Configuring Hostname"
hostnamectl set-hostname k8s.example.com

echo "[TASK 3] Update /etc/resolv.conf file"
cat >>/etc/resolv.conf<<EOF
nameserver 8.8.8.8
nameserver 192.168.0.1  
EOF

echo "[TASK 4] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.0.140     k8s.example.com     k8s
192.168.0.141     node.example.com    node
EOF

echo "[TASK 5] Checking Updates & Installing Bash-completion"
yum update -y >/dev/null 2>&1
yum install bash-completion -y >/dev/null 2>&1

echo "[TASK 6] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 7] Stop and Disable firewall"
systemctl stop firewalld && systemctl disable firewalld >/dev/null 2>&1


echo "[TASK 8] Letting iptables see bridged traffic"
modprobe br_netfilter

echo "[TASK 9] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/k8s.conf<<EOF
br_netfilter
EOF

echo "[TASK 10] Add Kernel settings"
cat >>/etc/sysctl.d/k8s.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1

echo "[TASK 11] Install docker"
yum install -y yum-utils >/dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y >/dev/null 2>&1

echo "[TASK 12] Configure the Docker daemon, in particular to use systemd for the management of the container’s cgroups."
mkdir /etc/Docker
cat >>/etc/docker/daemon.json<<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
    "max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF

echo "[TASK 13] Enable & Start Docker-Services"
systemctl enable --now docker
systemctl daemon-reload
systemctl restart docker
# systemctl status docker.service

echo "[TASK 14] Add apt repo for kubernetes"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

echo "[TASK 15] Install & Step Kubernetes-Packages"
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes >/dev/null 2>&1

echo "[TASK 16] Start & Enable Kubelet-Services"
systemctl enable --now kubelet
systemctl start kubelet
# systemctl restart kubelet

echo "[TASK 17] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

# echo "[TASK 18] Set root password"
# echo -e "sam\nsam" | passwd root >/dev/null 2>&1
# echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 19] Pull required containers"
kubeadm config images pull >/dev/null 2>&1

echo "[TASK 20] Remove containerd"
rm /etc/containerd/config.toml
systemctl restart containerd

echo "[TASK 21] Initialize Kubernetes Cluster"
#kubeadm init --apiserver-advertise-address=172.16.16.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null
kubeadm init --pod-network-cidr 192.168.0.0/16 --apiserver-advertise-address=192.168.0.140>> /root/kubeinit.log

echo "[TASK 22] Deploy Calico network"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml >/dev/null 2>&1
# kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1


echo "[TASK 23] Setup kubectl"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

echo "[TASK 24] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh

echo "[TASK 25] Configure Bash-completion"
kubectl completion bash > ~/.kube/kubecom.sh
