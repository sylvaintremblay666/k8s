# Log / Journal

Here, I'll try to keep a journal of what I'm doing on the cluster to help my poor aging failing memory :P. I won't write everything in there tho, the git history and the *READMEs* are there for this reason! :)

## Between [2020 Mar 24] and [2020 Apr 10]
As you can guess, I started writing this log on Apr 10th

### Helm
I installed _helm 3_ on _k8s-master_, see [README.md](./helm/README.md)


## [2020 Mar 23]
The birth of the cluster!

#### Cluster Description
- K8s: 1.17.4
- Docker: 19.3.8
- hybrid architecture (controller on *ARM*, nodes on *AMD64*)
- 1 controller and 2 nodes
- [Weave Net](https://www.weave.works/products/weave-net/) networking


#### BMs
##### Controller [k8s-master]
- Raspberry Pi 3B
- *ARMv7 Processor rev 4 (v7l) @ 1.2GHz* [4 cores]
- 1GB Ram
- [120GB SSD] *Kingston ssdNOW uv300* via USB2 [ext4]
- Raspbian 10 [buster]

##### Node1 [bigmonster]
- Supermicro X9DAi/X9DAi custom build
- 2x *Intel(R) Xeon(R) CPU E5-2620 v2 @ 2.10GHz* [24 cores]
- 128GB Ram
- Root disk : [128GB SSD] *Crucial_CT128MX1* [ext4]
- Data disks : 4x [2TB SATA 5400RPM] *WDC WD20EFRX-68E (RED)* [raidz1-0]
- Ubuntu 18.04 bionic

##### Node2 [x3650]
- IBM X3650 1U Server
- 2x *Intel(R) Xeon(R) CPU X5660 @ 2.80GHz* [24 cores]
- 64GB Ram
- Root disk : [146GB SAS 10k] *IBM MBD2147RC* [ext4]
- Data disks : 5x [146GB SAS 15K] *Fujitsu MBE2147RC* [raidz1-0]
- Ubuntu 18.04 bionic

### Notes
- As I'm starting to write this a couple weeks later, I already forgot some details about what I did precisely. For the installation of docker and k8s on the controller and the nodes, I followed some guides found on the web. It's no use to give more details about that here :)
- Pre-requisites to the install on the RPi :
```
$ sudo sysctl net.bridge.bridge-nf-call-iptables=1
$ sudo dphys-swapfile swapoff
$ sudo dphys-swapfile uninstall
$ sudo update-rc.d dphys-swapfile remove
$ sudo systemctl disable dphys-swapfile
$ sudo swapon --summary
```

- I installed Weave Net for the networking
```
$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```
