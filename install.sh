#!/bin/bash

declare -A local_images=$(docker images  | awk 'NR!=1{print $1 ":" $2}')
unset is_exist_images
unset pull_error_images
unset pull_succeed_images

header(){
	echo ""
	echo "-----------------------------------------------------------------"
	echo "-                                                               -"
	echo "- Building kubernetes Cluster.                                  -"
	echo "- Docker Version docker-ce-17.03.1.ce-1.el7.centos.x86_64.      -"
	echo "- Kubernetes Version 1.12.1                                     -"
	echo "- Istio Version release-1.0-latest-daily                        -"
	echo "- Images From hub.docker.com/spwanghub                          -"
	echo "-                                            --@Author spwang   -"
	echo "-                                                               -"
	echo "-----------------------------------------------------------------"
	echo ""
}
footer(){
	echo ""
	echo "-----------------------------------------------------------------"
	echo ""
	echo "Result"


	if [[ ${#is_exist_images[@]} -ne 0 ]]; 
	then
		echo ""
		echo "    Local exist images"
		for i in ${!is_exist_images[@]}; 
		do
			echo "    " + ${is_exist_images[$i]}
		done
	fi

	if [[ ${#pull_succeed_images[@]} -ne 0 ]]; 
	then
		echo ""
		echo "    Succeed"
		for i in ${!pull_succeed_images[@]}; 
		do
			echo "    " + ${pull_error_images##*=}
		done
	fi

	if [[ ${#pull_error_images[@]} -ne 0 ]]; 
	then
		echo ""
		echo "    Error"
		for j in ${!pull_error_images[@]}; 
		do
			echo "    " + ${pull_error_images[$j]}
		done
		echo ""
		echo "    Please try again pull images"
		for j in ${!pull_error_images[@]}; 
		do
			echo "       docker pull" ${pull_error_images%%=*}
			echo "       docker tag" ${pull_error_images%%=*} ${pull_error_images##*=}
		done
	fi

	echo ""
	echo "Finish ..."
	echo "-----------------------------------------------------------------"
}
download_image(){
	key=$1
	value=$2
	if [[ $(echo $local_images |grep $value) == "" ]];
	then
		echo ""
	    echo -e "\033[32m> docker pull $key \033[0m"
		docker pull $key
		if [ $? -ne 0 ]
		then
		    pull_error_images=(${pull_error_images[@]} $key'='$value)
		else
		  	echo -e "\033[32m> docker tag $key $value \033[0m"
			docker tag $key $value    
			echo -e "\033[32m> docker rmi -f $key \033[0m"
			docker rmi -f $key 
			pull_succeed_images=(${pull_succeed_images[@]} $value) 
		fi
	else
	    is_exist_images=(${is_exist_images[@]} $value)
	fi
}
install_docker_and_kubernetes(){
	yum install -y ./rpm/*.rpm

	systemctl daemon-reload && systemctl restart docker && systemctl enable docker

	systemctl enable kubelet && systemctl start kubelet
}


declare -A kubernetes_images=(
	['spwanghub/kube-apiserver:v1.12.1']='k8s.gcr.io/kube-apiserver:v1.12.1'
	['spwanghub/kube-controller-manager:v1.12.1']='k8s.gcr.io/kube-controller-manager:v1.12.1'
	['spwanghub/kube-proxy:v1.12.1']='k8s.gcr.io/kube-proxy:v1.12.1'
	['spwanghub/kube-scheduler:v1.12.1']='k8s.gcr.io/kube-scheduler:v1.12.1'
	['spwanghub/coredns:1.2.2']='k8s.gcr.io/coredns:1.2.2'
	['spwanghub/etcd:3.2.24']='k8s.gcr.io/etcd:3.2.24'
	['spwanghub/pause:3.1']='k8s.gcr.io/pause:3.1'
	['spwanghub/node:v3.1.3']='quay.io/calico/node:v3.1.3'
	['spwanghub/cni:v3.1.3']='quay.io/calico/cni:v3.1.3'
	['spwanghub/kubernetes-dashboard-amd64:v1.12.0']='k8s.gcr.io/kubernetes-dashboard-amd64:v1.12.0'
)

declare -A istio_images=(
    ['spwanghub/proxy_init:release-1.0-latest-daily']='gcr.io/istio-release/proxy_init:release-1.0-latest-daily'
    ['spwanghub/galley:release-1.0-latest-daily']='gcr.io/istio-release/galley:release-1.0-latest-daily'
    ['spwanghub/proxyv2:release-1.0-latest-daily']='gcr.io/istio-release/proxyv2:release-1.0-latest-daily'         
    ['spwanghub/mixer:release-1.0-latest-daily']='gcr.io/istio-release/mixer:release-1.0-latest-daily'      
    ['spwanghub/pilot:release-1.0-latest-daily']='gcr.io/istio-release/pilot:release-1.0-latest-daily'
    ['spwanghub/citadel:release-1.0-latest-daily']='gcr.io/istio-release/citadel:release-1.0-latest-daily'
    ['spwanghub/sidecar_injector:release-1.0-latest-daily']='gcr.io/istio-release/sidecar_injector:release-1.0-latest-daily'
    ['spwanghub/prometheus:v2.3.1']='docker.io/prom/prometheus:v2.3.1'
    ['spwanghub/hyperkube:v1.7.6_coreos.0']='quay.io/coreos/hyperkube:v1.7.6_coreos.0'
)

header

echo -e "\033[32m> Install docker kubeadm kubectl kubelet \033[0m"
install_docker_and_kubernetes

echo -e "\033[32m> Downloading Kubernetes dependence \033[0m"
for key in ${!kubernetes_images[@]}  
do  
	download_image $key ${kubernetes_images[$key]}
done	

echo ""
echo -e "\033[32m> Downloading Istio dependence \033[0m"
for key in ${!istio_images[@]}  
do  
	download_image $key ${istio_images[$key]}
done

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
kubectl create -f ./yml/kubernetes-dashboard.yaml
kubectl create -f ./yml/heapster-controller.yaml

footer
