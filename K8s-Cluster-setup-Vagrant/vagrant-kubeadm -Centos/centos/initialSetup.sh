export DEBIAN_FRONTEND=noninteractive

echo "[TASK 1] show whoami"
whoami

echo "[TASK 2] Stop and Disable firewall"
systemctl stop firewalld && systemctl disable firewalld >/dev/null 2>&1


echo "[TASK 3] Letting iptables see bridged traffic"
modprobe br_netfilter

echo "[TASK 4] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/k8s.conf<<EOF
br_netfilter
EOF

echo "[TASK 5] Add Kernel settings"
cat >>/etc/sysctl.d/k8s.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo "[TASK 6] Install docker"
yum update -y >/dev/null 2>&1
yum install -y yum-utils >/dev/null 2>&1
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null 2>&1
yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y >/dev/null 2>&1

echo "[TASK 6] Configure the Docker daemon, in particular to use systemd for the management of the container’s cgroups."
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
systemctl enable --now docker
systemctl daemon-reload
systemctl restart docker
# systemctl status docker.service

echo "[TASK 7] Add apt repo for kubernetes"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

echo "[TASK 8] Install & Step Kubernetes-Packages"
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes >/dev/null 2>&1

echo "[TASK 9] Start & Enable Kubelet-Services"
systemctl enable --now kubelet
systemctl start kubelet
systemctl restart kubelet

echo "[TASK 10] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 11] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 12] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.16.16.101   k8s.example.com       k8s
172.16.16.102   kNode1.example.com    kNode1
172.16.16.103   kNode2.example.com    kNode2
EOF
