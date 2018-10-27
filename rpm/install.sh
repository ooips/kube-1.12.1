#!/bin/sh

rpm -i docker-ce-selinux-17.03.3.ce-1.el7.noarch.rpm
rpm -i docker-ce-17.03.1.ce-1.el7.centos.x86_64.rpm

rpm -i kubernetes-cni-0.6.0-0.x86_64.rpm
rpm -i kubectl-1.12.1-0.x86_64.rpm
rpm -i kubelet-1.12.1-0.x86_64.rpm
rpm -i cri-tools-1.12.0-0.x86_64.rpm
rpm -i kubeadm-1.12.1-0.x86_64.rpm
