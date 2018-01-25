#!/bin/bash
set -e

#sudo apt-get install -y docker.io libvirt-bin virt-manager qemu qemu-efi

#!/bin/bash
dir=`pwd`
echo "Current dir: "$dir
curdir=${dir##*/}
result=$(echo $curdir | grep "compass4nfv")
if [[ "$result" == "" ]]
then
    cd compass4nfv
fi

CONTAINER4NFV_SCENARIO=2flannels

export ADAPTER_OS_PATTERN='(?i)CentOS-7.*arm.*'
export OS_VERSION="centos7"
export KUBERNETES_VERSION="v1.7.3"
export DHA="deploy/conf/vm_environment/k8-nosdn-nofeature-noha.yml"
export NETWORK="deploy/conf/vm_environment/network.yml"
export VIRT_NUMBER=2 VIRT_CPUS=2 VIRT_MEM=4096 VIRT_DISK=50G

if [ $CONTAINER4NFV_SCENARIO = 2flannels ]; then
  # enable 2 flannel cni deployment
  echo "Set 2flannel scenario"
  sed -i.bak 's/^kube_network_plugin:.*$/kube_network_plugin: 2flannel/' \
    deploy/adapters/ansible/kubernetes/roles/kargo/files/extra-vars-aarch64.yml
fi

./deploy.sh

set -ex

# basic test: ssh to master, check k8s node status
sshpass -p root ssh root@10.1.0.50 kubectl get nodes 2>/dev/null | grep -i ready

# scenario specific tests
if [ $CONTAINER4NFV_SCENARIO = 2flannels ]; then
# show two nics in container
  sshpass -p root ssh root@10.1.0.50 \
    kubectl run test-2flannel --rm --restart=Never -it --image=busybox -- ip a
fi
