#!/bin/sh

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update && apt-get install -y kubelet kubeadm kubectl

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

mkdir /etc/etcd /var/lib/etcd
mv ca.pem kubernetes.pem kubernetes-key.pem /etc/etcd
wget https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz
tar xvzf etcd-v3.3.13-linux-amd64.tar.gz





