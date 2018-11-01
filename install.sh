
cd kube-1.12.1

yum install -y ./images/*.rpm

docker pull spwanghub/kube-1.12.1:kube-apiserver
docker pull spwanghub/kube-1.12.1:kube-controller-manager
docker pull spwanghub/kube-1.12.1:kube-proxy
docker pull spwanghub/kube-1.12.1:kube-scheduler
docker pull spwanghub/kube-1.12.1:coredns
docker pull spwanghub/kube-1.12.1:etcd
docker pull spwanghub/kube-1.12.1:pause
docker pull spwanghub/kube-1.12.1:calico
docker pull spwanghub/kube-1.12.1:calico-cni

docker tag spwanghub/kube-1.12.1:kube-apiserver k8s.gcr.io/kube-apiserver:v1.12.1
docker tag spwanghub/kube-1.12.1:kube-controller-manager k8s.gcr.io/kube-controller-manager:v1.12.1
docker tag spwanghub/kube-1.12.1:kube-proxy k8s.gcr.io/kube-proxy:v1.12.1
docker tag spwanghub/kube-1.12.1:kube-scheduler k8s.gcr.io/kube-scheduler:v1.12.1
docker tag spwanghub/kube-1.12.1:coredns k8s.gcr.io/coredns:1.2.2
docker tag spwanghub/kube-1.12.1:etcd k8s.gcr.io/etcd:3.2.24
docker tag spwanghub/kube-1.12.1:pause k8s.gcr.io/pause:3.1
docker tag spwanghub/kube-1.12.1:calico quay.io/calico/node:v3.1.3
docker tag spwanghub/kube-1.12.1:calico-cni quay.io/calico/cni:v3.1.3

docker rmi -f spwanghub/kube-1.12.1:kube-apiserver
docker rmi -f spwanghub/kube-1.12.1:kube-controller-manager
docker rmi -f spwanghub/kube-1.12.1:kube-proxy
docker rmi -f spwanghub/kube-1.12.1:kube-scheduler
docker rmi -f spwanghub/kube-1.12.1:coredns
docker rmi -f spwanghub/kube-1.12.1:etcd
docker rmi -f spwanghub/kube-1.12.1:pause
docker rmi -f spwanghub/kube-1.12.1:calico
docker rmi -f spwanghub/kube-1.12.1:calico-cni


echo "
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
" >> /etc/sysctl.conf

echo "vm.swappiness=0" >> /etc/sysctl.conf

sysctl -p

swapoff -a

kubeadm reset

kubeadm init --kubernetes-version=v1.12.1 --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=0.0.0.0

kubectl create -f ./yml/calico.yaml
kubectl create -f ./yml/rbac-kdd.yaml
