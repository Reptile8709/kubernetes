# Step-1) Update the os
             i.e yum udate (CentOs) / apt update (Ubuntu)

# Step-2) Set Hostname
            i.e hostnamectl set-hostname <name>

# Step-3) Update Host File
            i.e vi /etc/hosts

# Step-4) Disable the swap memory
            i.e swapoff -a
                vi /etc/fstab (comment the swap line)

# Step-5) Disable the Firewall.service
            i.e systemctl stop firewalld && systemctl disable firewalld (CentOs)
                systemctl stop ufw & systemctl disable ufw (Ubuntu)

# Step-6) Install Docker from Official Website

# Step-7) Start the Docker service
            i.e systemctl start docker
                systemctl enable docker
                systemctl restart docker

# Step-8) Install Kubernetes from Official Website
            i.e search install kubeadm

# Step-9) Remove Containerd Directory and restart the service
            i.e  rm /etc/containerd/config.toml
                 systemctl restart containerd

# Step-10) Initiate the Kubeadm and assign CIDR for POD
            i.e kubeadm init --pod-network-cidr=<CIDR>
                        
                kubeadm init --pod-network-cidr=192.168.0.0/24 --apiserver-advertise-address=192.168.0.0/16
                kubeadm init --apiserver-advertise-address=172.16.16.100 --pod-network-cidr=192.168.0.0/16


# Step-11) Create and Apply Weave CNI
            i.e kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1 weave-daemonset-k8s.yaml

                kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml

           kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

If you are using fannel-network and having multiple interface, than don't apply directly the fannel yaml file. Just download and do some changes
  i.e. wget <fennel-network-yaml-file>
       than open the yaml file and search /fanneld, in below <arg> section add -- iface=<interface-name>


# Step-12) Now Check the Node is Ready or not and Also the Namespace
                i.e kubectl get nodes
                    Kubectl get pod -A

# Step-13)add the another node in cluster by pasting the command
                i.e kubeadm join <Detail will get when you initiate the kubeadm init command, copy and paste in other node>

# Step-14) Finally, check the node is added or not in cluster
                i.e kubectl get nodes

# STEP-15) Check control-plane components are healthy or not
                i.e.  kubectl get componentstatus / kubectl get cs

# STEP16) To Use kubectl command from different machine like windows/other-linux-machine, than create one directory ./kube and follow below steps
                i.e. scp root@<IP-Address-of-Master>  ~./kube/config (Directory of other machine)

# ###############################################################
# TO MAKE AUTO-COMPLETION OF KUBECTL, FOLLOW BELOW STEPS
# ###############################################################
Kubectl completion bash > kubecom.sh
Export $HOME/.kube/kubecom.sh
source $HOME/.kube/kubecom.sh

# ##############################################################
# MAKE KUBECONFIG IN BASH-PROFILE,
# ############################################################
export KUBECONFIG=${HOME}/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

# ############################################################
# IF ERROR WILL SHOW RELATED TO IPTABLES, THAN FOLLOW BELOW STEPS
# ############################################################
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo "net.bridge.bridge-nf-call-iptables = 1" > /etc/sysctl.conf

vi /etc/sysctl.conf
net.bridge.bridge-nf-call-iptables = 1
sysctl -p

# ######################################
# TO CONFIGURE JAVA_HOME
# ######################################

echo JAVA_HOME=/usr/bin/java
Export PATH=$JAVA_HOME/bin:$PATH

source .bash_profile




# ##############################################################################################
                       TROUBLESHOOT

systemctl restart kubelet
systemctl start kubelet
systemctl status kubelet
strace -eopenat kubectl version
systemctl restart containerd
