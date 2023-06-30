export DEBIAN_FRONTEND=noninteractive

echo "[TASK 1] show whoami"
whoami

echo "[TASK 2] Stop and Disable firewall"
systemctl stop ufw >/dev/null 2>&1
systemctl disable --now ufw >/dev/null 2>&1

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
sysctl --system >/dev/null 2>&1

echo "[TASK 6] Install Docker-Dependencies"
apt-get update >/dev/null 2>&1
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release >/dev/null 2>&1

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
     "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null 2>&1

echo "[TASK 7] Install Docker-Packages"
apt-get update >/dev/null 2>&1
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y >/dev/null 2>&1
# apt-get install docker-ce docker-ce-cli containerd.io -y

echo "[TASK 8] Configure the Docker daemon, in particular to use systemd for the management of the container’s cgroups."
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

echo "[TASK 9] Installing dependencies"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl -y

echo "[TASK 10] Add apt repo for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >/dev/null 2>&1
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/dev/null 2>&1

echo "[TASK 11] Install Kubernetes-Packages"
apt-get update
apt-get install -y kubelet kubeadm kubectl
# apt-get install -y kubelet=1.22.2-00 kubeadm=1.22.2-00 kubectl=1.22.2-00 -y

echo "[TASK 12] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 13] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 14] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.16.16.101   k8s.example.com       k8s
172.16.16.102   kNode1.example.com    kNode1
172.16.16.103   kNode2.example.com    kNode2
EOF
