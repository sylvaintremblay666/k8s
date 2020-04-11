# Log / Journal

Here, I'll try to keep a journal of what I'm doing on the cluster to help my poor aging failing memory :P. I won't write everything in there tho, the git history and the *READMEs* are there for this reason! :)

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
## [2020 Mar 24]

### Helm
I installed _helm 3_ package manager on _k8s-master_, see [README.md](./helm/README.md)

### nfs_client_provisioner
I needed something for persistent storage, went with the easy solution of `nfs_client_provisioner`. It creates folders for persistent storage on an already existing nfs shared folder. See [README](./helm/nfs_client_provisioner.md)



## [2020 Apr 10]

- Started the git repo and my documentation efforts
- Made cadvisor work! issues with the tags tho, something's not working properly, the TagOverride from the doc to parse docker_name isn't working so I'm not getting proper container / pod names for now...
- Have my own multi-stage build for cadvisor, I will have to make it multi-arch (docker buildx) so it runs on the ARMv7 architecture too.
- Almost nothing is pushed to GitHub yet, will work on that

## [2020 Apr 11] (Saturday, easter week-end)

Well, looks like it's not gonna be easy to keep this up-to-date! Need more discipline :P

- Wrote a few entries ^^ , still a lot to do and to upload to GitHub
- Spent lots of time working on cadvisor/scollector tags... Finally figured out the regex in the example wasn't right for what I am receiving in `docker_name` ...! Don't ask me why tho, no idea... seems like the format from the doc isn't the same as the one I'm getting with the latest versions I installed (I build scollector / cadvisor from the source when building my docker images). The regex is in the `scollector-daemonset.yaml` file (the config file is dynamically built on container startup, a variable is set to add the cadvisor config block in it)
- To remove a tag from opentsdb connect to the opentsdb pod then
```
$ cd bin
$ tsdb uid grep tagk <tag key> # to view the tag
$ tsdb uid delete tagk <tag key> #
```
When done, to remove the tag from bosun, clear it's cache (restart it's container in my case as I'm using internal ledis without persistence)
- Updated my scollector docker image build to multi-stage so the final image is a clean alpine with only the binary, reduced my image from 2.07GB to 27.5MB ! :-D No need for the build tools in the final image...!
- Created my multi-arch image for cadvisor, 41.3MB total.

I'm starting to get metrics on my stuff, that's really nice!! I need to create a persistent volume for my graphana and start creating dashboards :-) I will then need to deal with my logfiles! But I'm not there yet.
