----------------------------------------------------------------------------------------------------------------------------
## Setup Single Master/multiple worker nodes:
## Source - https://medium.com/htc-research-engineering-blog/install-a-kubernetes-cluster-with-kubeadm-on-ubuntu-step-by-stepff-c118514bc5e0
----------------------------------------------------------------------------------------------------------------------------

##Prerequisite:
Number of VM's - 4
Type of VM's - 1 Master, 3 Worker Nodes
Machine type - n1-standard-8
Image version - ubuntu-1804-lts
VPC - Single Region
Internet connectivity - For internal IP through cloud NAT/router
External IP for the VM's through ephimeram VM
L4 loadbalancer with the nodeport  with the external IP

## Configure IPtables ####
vi /etc/ufw/sysctl.conf
net/bridge/bridge-nf-call-ip6tables = 1
net/bridge/bridge-nf-call-iptables = 1
net/bridge/bridge-nf-call-arptables = 1

###Install dependency
apt-get update && apt-get install -y apt-transport-https

##Add kubernetes repository key##
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

##Add kubernetes repository manifests##
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

##Install the kubeadm, kubelet and kubectl
apt-get update && apt-get install -y kubelet kubeadm kubectl docker.io

##Initialize the kubeadm & podnetwork:
kubeadm init --pod-network-cidr=192.168.0.0/16


Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.128.0.96:6443 --token 7wki61.1t6qovh2rdoaelvw \
    --discovery-token-ca-cert-hash sha256:b21d059dfe88d8875620b87a65215adc0bb2b0a5b5b0888eb781b44adfc9c220


##Copy kubectl to .kube folder for this user:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


##Install Network plugin/Network services for the kubernetes cluster:
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml


##Taint the nodes not to schedule any pod in master:
kubectl taint nodes --all node-role.kubernetes.io/master


##Update the DNS server in the master node to use the coredNS the open source name server.
/etc/resolv.conf 
nameserver 8.8.4.4
nameserver 8.8.8.8

##Use the kubect join node for the worker nodes after completing the basic installation.
kubeadm join 10.128.0.96:6443 --token 7wki61.1t6qovh2rdoaelvw \
    --discovery-token-ca-cert-hash sha256:b21d059dfe88d8875620b87a65215adc0bb2b0a5b5b0888eb781b44adfc9c220

## For labelling the worker node as worker ##
kubectl label node <NodeName> node-role.kubernetes.io/worker=worker

## Validation ###
1) Deploy a test application and test whether the pods are coming up.
kubectl run hello --image=k8s.gcr.io/echoserver:1.4 --port=8080
2) Validate whether the node is healthy
"kubectl get node"
3) Verify all the network pods are in running state


----------------------------------------------------------------------------------------------------------------------------
Setup multiple master node/ single worker nodes:
## Source ## https://dockerlabs.collabnix.com/kubernetes/beginners/Install-and-configure-a-multi-master-Kubernetes-cluster-with-kubeadm.html
----------------------------------------------------------------------------------------------------------------------------

##Prerequisite
Setup 6 nodes
10.128.0.99 - HA proxy
10.128.0.97 - Master 1
10.128.0.120 - Master 2
10.128.0.98 - Master 3
10.128.0.121 - Worker
Number of VM's - 6
Type of VM's - 3 Master, 1 Worker Node, 1 HA proxy
Machine type - n1-standard-8
Image version - ubuntu-1804-lts
VPC - Single Region
Internet connectivity - For internal IP through cloud NAT/router
External IP for the VM's through ephimeram VM
L4 loadbalancer for the backend with internal IP


## On the HA proxy Server - 10.128.0.99

## 1) Certificate generation dependancy - cfssl
$ wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
$ wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssl*
$ sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
$ sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
$ cfssl version

## 2) Install kubectl
wget https://storage.googleapis.com/kubernetes-release/release/v1.15.0/bin/linux/amd64/kubectl
$chmod +x kubectl
$sudo mv kubectl /usr/local/bin
kubectl version


## 3) installation 
apt-get update
apt-get install haproxy

## 4) Setup proxy with the master node details.
vim /etc/haproxy/haproxy.cfg
global
...
default
...
frontend kubernetes
bind <HA proxy_server>:6443
option tcplog
mode tcp
default_backend kubernetes-master-nodes
backend kubernetes-master-nodes
mode tcp
balance roundrobin
option tcp-check
server k8s-master-0 <Master-node-1>:6443 check fall 3 rise 2
server k8s-master-1 <Master-node-2>:66443 check fall 3 rise 2
server k8s-master-2 <Master-node-3>:66443 check fall 3 rise 2

sudo systemctl restart haproxy


## 5) Certificate Generation:

vim ca-config.json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}

vim ca-csr.json
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
  {
    "C": "IE",
    "L": "Cork",
    "O": "Kubernetes",
    "OU": "CA",
    "ST": "Cork Co."
  }
 ]
}

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

###Certificate for etcd cluster: Generate certificate for etcd cluster
$ vim kubernetes-csr.json
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
  {
    "C": "IE",
    "L": "Cork",
    "O": "Kubernetes",
    "OU": "Kubernetes",
    "ST": "Cork Co."
  }
 ]
}


cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-hostname=10.10.10.90,10.10.10.91,10.10.10.92,10.10.10.93,127.0.0.1,kubernetes.default \
-profile=kubernetes kubernetes-csr.json | \
cfssljson -bare kubernetes

    ## Copy the certs to the nodes
    $ scp ca.pem kubernetes.pem kubernetes-key.pem ubuntu@<masternode1>:~
    $ scp ca.pem kubernetes.pem kubernetes-key.pem ubuntu@1<masternode2>:~
    $ scp ca.pem kubernetes.pem kubernetes-key.pem ubuntu@<masternode3>:~

## 6) Install the below dependancies in the 3 master and 1 worker node
        ###Install dependency
        apt-get update && apt-get install -y apt-transport-https

        ##Add kubernetes repository key##
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

        ##Add kubernetes repository manifests##
        cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
        deb http://apt.kubernetes.io/ kubernetes-xenial main
        EOF

        ##Install the kubeadm, kubelet and kubectl
        apt-get update && apt-get install -y kubelet kubeadm kubectl docker.io

## 7) Setup ETCD on the master server:
Installing and configuring Etcd on the 3 master machine (All 3 master)
    ##Copy the certs to the folder
    mkdir /etc/etcd /var/lib/etcd
    sudo mv ~/ca.pem ~/kubernetes.pem ~/kubernetes-key.pem /etc/etcd
    ##Download etcd binary
    wget https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz
    ##Extract the binary
    tar xvzf etcd-v3.3.13-linux-amd64.tar.gz
    sudo mv etcd-v3.3.13-linux-amd64/etcd* /usr/local/bin/
    ##Etcd configuration file point to the master node service.
    ##Refer the etcd/init-service
    ##systemctl daemon-reload
    ##systemctl enable etcd
    ##systemctl start etcd
    ##Refer logs - journalctl -u etcd
    ## Verify members - ETCDCTL_API=3 etcdctl member list

## 8) Initialize in the master node.

##kubeadm init --config=config.yaml
    apiVersion: kubeadm.k8s.io/v1beta1
    kind: ClusterConfiguration
    kubernetesVersion: stable
    apiServerCertSANs:
    - 10.128.0.99
    controlPlaneEndpoint: "10.128.0.99:6443"
    etcd:
    external:
        endpoints:
        - https://10.128.0.97:2379
        - https://10.128.0.120:2379
        - https://10.128.0.98:2379
        caFile: /etc/etcd/ca.pem
        certFile: /etc/etcd/kubernetes.pem
        keyFile: /etc/etcd/kubernetes-key.pem
    networking:
    podSubnet: 192.167.0.0/16
    apiServerExtraArgs:
    apiserver-count: "3"

## Copy the certificate to the other master nodes after certificate installation.
$ sudo scp -r /etc/kubernetes/pki ubuntu@<master-node2>:~
$ sudo scp -r /etc/kubernetes/pki ubuntu@<master-node3>:~


##Initialize the master in other two nodes:
##Remove this,
rm ~/pki/apiserver.* - 
##Move this to the kubernetes directory
mv ~/pki /etc/kubernetes/


## 9) Join the worker node to the master kubernetes

kubeadm join 10.128.0.99:6443 --token 6adfyd.bw1r2bnyoxotd711 \
    --discovery-token-ca-cert-hash sha256:614a77c80935de6eaac4af4cd8ea8ba69b3a74286c3e5241a9f09a5e9b02882e

## 10) Join any control plane node with the master cluster
  kubeadm join 10.128.0.99:6443 --token 6adfyd.bw1r2bnyoxotd711 \
    --discovery-token-ca-cert-hash sha256:614a77c80935de6eaac4af4cd8ea8ba69b3a74286c3e5241a9f09a5e9b02882e \
    --control-plane

## 11) Install overlay network 
kubectl apply -f https://docs.projectcalico.org/v3.7/manifests/calico.yaml

## 12) Validation ###
1) Deploy a test application and test whether the pods are coming up.
kubectl run hello --image=k8s.gcr.io/echoserver:1.4 --port=8080
2) Validate whether the node is healthy
"kubectl get node"
3) Verify all the network pods are in running state

