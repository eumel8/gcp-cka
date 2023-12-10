# Install Kubernetes with Kubeadm

This lab will setup Kubernetes with Kubeadm. See [official documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/), which is allowed during CKA exam.

Requirements for hardware and operating systems are:

- VM 2 CPU/4 GB Ram
- Debian 11 Bullseye

- Firewall settings, following [Kubernetes Docs](https://v1-25.docs.kubernetes.io/docs/reference/networking/ports-and-protocols/#control-plane)

# Swap, Kernel Modules, Kernel Configuration

Swap needs to switch off, otherwise Kubelet won't start:

```bash
swapoff -a
``` 

Check if swap is permanently configured:

vi /etc/fstab 

We need Kernel modules and configuration for Overlay and Bridge Netfilter:

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```

- needs [iptables-legacy] for iptables backend
- if nftables is enabled, change to [iptables-legacy]

```bash
update-alternatives --config iptables  
```

# CRI: 

see [Official docs](https://v1-25.docs.kubernetes.io/docs/setup/production-environment/container-runtimes/)

## containerd/dockerd:

### add repository to Apt sources

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
```

### install containerd

```bash
apt-get install containerd.io
```

### or install docker

```bash
apt-get install docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
```

### cri plugin in containerd plugin is disabled by default

```
sed -i 's/disabled_plugins/# disabled_plugins/' /etc/containerd/config.toml
systemctl restart containerd.service
```

### set cgroup v2 driver to systemd

vi /etc/containerd/config.toml:

```
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
   [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
 ```    

### configure crictl

vi /etc/crictl.yaml

```
runtime-endpoint: "unix:///run/containerd/containerd.sock"
timeout: 0
debug: false
```

```bash
systemctl restart containerd.service
```

or 

## cri-o

### add repository to Apt sources

```bash
mkdir -p /usr/share/keyrings
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.28/Debian_11/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.28/Debian_11/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:1.28.list

apt-get update
```

### install cri-o

```
apt-get install -y cri-o cri-o-runc
```

crio-io comes with crio-bridge, you don't need additional CNI driver

https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/

# Kubeadm

### add repository to Apt sources

```
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

apt update
```

### install kubeadm

``` 
apt-get install -y kubeadm kubelet kubectl  
```

At this point you have a running container runtime containerd, cri-o, or docker. This should stable run. Especially containerdneeds this adjustments for cgroup. There are cgroup v1 and v2, managed by itself or systemd. If this is wrong configured, kubelet won't start or give errors.

# init cluster

Dependly on the container runtime kubeadm needs connect the right socket. There might be some defaults/auto-discovery, or we set this to our installed service.
After this step we need to install Container Network Interface (CNI). There are various options with various default settings. We pick up some of them and dependly configure the Pod network. The control-plane-endpoint is the network interface of the `master` node which is dynamically set per DHCP but to 99% 10.0.1.2:

```
# canal/weave
kubeadm init --control-plane-endpoint=10.0.1.2 --pod-network-cidr=10.244.0.0/16 --cri-socket=unix:///run/containerd/containerd.sock 
# calico
kubeadm init --control-plane-endpoint=10.0.1.2 --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///run/containerd/containerd.sock 
```

# kubeconfig

setup kube config to access the cluster, set auto completion in shell:

```
export KUBECONFIG=/etc/kubernetes/admin.conf
source <(kubectl completion bash)
```

# CNI

see [Official docs](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy)

## choose a CNI driver

```
  canal:
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/canal.yaml 
  
  calico:
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/tigera-operator.yaml --server-side --force-conflicts
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/custom-resources.yaml
  
  Weave:
  kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```  

if the driver pod won't start check CIDR settings

# Worker nodes

Needs preparation like master node beside the `kubeadm init` and CNI deployment. This will be done from the master node:

Create token on master node if you missed it on the init output and execute the output on worker:

``` 
kubeadm token create --print-join-command
```

# Verify

```
root@master:~# kubectl get nodes
NAME     STATUS   ROLES           AGE   VERSION
master   Ready    control-plane   32m   v1.28.4
node1    Ready    <none>          82s   v1.28.4
root@master:~# kubectl get pods -A
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-7c968b5878-j2s7t   1/1     Running   0          16m
kube-system   canal-cpl7p                                2/2     Running   0          106s
kube-system   canal-t524t                                2/2     Running   0          87s
kube-system   coredns-5dd5756b68-6st6k                   1/1     Running   0          31m
kube-system   coredns-5dd5756b68-scgn8                   1/1     Running   0          31m
kube-system   etcd-master                                1/1     Running   0          32m
kube-system   kube-apiserver-master                      1/1     Running   0          32m
kube-system   kube-controller-manager-master             1/1     Running   0          32m
kube-system   kube-proxy-86v9l                           1/1     Running   0          31m
kube-system   kube-proxy-bz8j7                           1/1     Running   0          87s
kube-system   kube-scheduler-master                      1/1     Running   0          32m
```

# Debugging

 See [official documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/)

## kubelet

```
journalctl  -u kubelet |less
```
