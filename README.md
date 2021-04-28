# Kubernetes installation

## Pre-requisites

### On your local machine

Install Terraform.

```sh
cat > hashicorp.repo <<"EOF"
[hashicorp]
name=Hashicorp Stable - $basearch
baseurl=https://rpm.releases.hashicorp.com/RHEL/8/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://rpm.releases.hashicorp.com/gpg
EOF
sudo dnf config-manager --add-repo hashicorp.repo
sudo dnf -y install terraform
```

Install the libvirt terraform provider.

```sh
curl -Lo /tmp/libvirt-provider.tgz https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.6.3/terraform-provider-libvirt-0.6.3+git.1604843676.67f4f2aa.Fedora_32.x86_64.tar.gz
mkdir -p ~/.terraform.d/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64
tar xvf /tmp/libvirt-provider.tgz -C ~/.terraform.d/plugins/registry.terraform.io/dmacvicar/libvirt/0.6.3/linux_amd64
```

Initialize Terraform.

```sh
cd terraform
terraform init
```

Install kubespray dependencies.

```sh
sudo dnf install ansible python3-netaddr python3-pbr python3-ruamel-yaml python3-jmespath
```

### On the hypervisor

Install libvirt.

```sh
sudo dnf install libvirt libvirt-daemon-kvm virt-install virt-viewer virt-top libguestfs-tools nmap-ncat
```

Fetch the latest CentOS Stream 8 cloud image.

```sh
sudo curl -Lo /var/lib/libvirt/images/centos-stream-8.qcow2 http://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20201217.0.x86_64.qcow2
```

## Install

Find a name for the cluster.

```sh
export CLUSTER_NAME=kube
```

Add the DNS entries to your DNS server (dnsmasq in the following example).

```sh
# Hosts
host-record=lb.kube.itix.lab,192.168.16.4,24h
host-record=storage.kube.itix.lab,192.168.16.6,24h
host-record=master1.kube.itix.lab,192.168.16.11,24h
host-record=master2.kube.itix.lab,192.168.16.12,24h
host-record=master3.kube.itix.lab,192.168.16.13,24h
host-record=worker1.kube.itix.lab,192.168.16.21,24h
host-record=worker2.kube.itix.lab,192.168.16.22,24h

# Services
host-record=api.kube.itix.lab,192.168.16.4,24h
cname=*.apps.kube.itix.lab,lb.kube.itix.lab
```

Deploy the Virtual Machines.

```sh
export LIBVIRT_DEFAULT_URI="qemu+ssh://$LIBVIRT_USER@$LIBVIRT_SERVER/system"
cd terraform
terraform init
terraform apply -var cluster_name=$CLUSTER_NAME
```

Set the default cluster variables.

```sh
cp -r inventory/sample/group_vars inventory/$CLUSTER_NAME/group_vars
```

Install Kubernetes.

```sh
cd ../kubespray
ansible -i inventory/$CLUSTER_NAME/inventory.ini all -m wait_for -a "port=22"
ansible-playbook -i inventory/$CLUSTER_NAME/inventory.ini cluster.yml
sudo chown -R $USER inventory/$CLUSTER_NAME/artifacts/
```

Ensure the cluster is up and running.

```sh
KUBECONFIG=inventory/$CLUSTER_NAME/artifacts/admin.conf kubectl get nodes
```

## Post-Install

Expose the dashboard.

```sh
KUBECONFIG=inventory/$CLUSTER_NAME/artifacts/admin.conf kubectl create ingress dashboard -n kube-system --rule "dashboard.apps.kube.itix.lab/*=kubernetes-dashboard:443,tls" --annotation=ingress.kubernetes.io/ssl-passthrough=true --annotation=nginx.ingress.kubernetes.io/backend-protocol=HTTPS --annotation=kubernetes.io/ingress.allow-http=false
```

Create the admin account.

```sh
export KUBECONFIG=inventory/$CLUSTER_NAME/artifacts/admin.conf
kubectl create sa admin -n kube-system
kubectl create clusterrolebinding admin --clusterrole=cluster-admin --serviceaccount=kube-system:admin -n kube-system
```

Fetch the admin password.

```sh
kubectl -n kube-system get secret $(kubectl -n kube-system get sa/admin -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
```
