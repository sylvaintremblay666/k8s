# nfs-client-provisioner

[GitHub](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner)

### Installation
- Created a zfs dataset on bigmonster, NFS shared
- Installed using helm :
```
helm install bigmonster --set replicacount=1 --set nfs.server=192.168.2.120 --set nfs.path=/data/k8s-persistent-storage stable/nfs-client-provisioner
```
