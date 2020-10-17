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

## [2020 Apr 12] Happy Easter!

- Destroyed / recreated opentsdb helm installation to reset all my data, worked well (be patient for the first start of all containers)
- Realized cadvisor has been at some point integrated into kubelet, and is not anymore, this is not the way to monitor these days... but it's still used... Need to read more on the subject! Still, I'm happy I made this thing work as I wanted to experiment with these tools.
- Found an interesting link on cadvisor: https://www.metricfire.com/blog/monitoring-docker-containers-with-cadvisor
- Prometheus definitely seems to be the way to go, I'll spend some time reading on the web about what's the recommended monitoring stack these days.

## [2020 Sep 19] Welcome back!

Well, got into health issues, stoped working for 4 months, and abandoned all my experiments. I restarted to work a month back, I getting better, and slowly finding interest back! Let's try to keep on with this project :)

- Yesterday, I realized my opentsdb cluster wasn't happy, not properly working anymore. Networking and DNS issues.
- The weave-network plugin wasn't working anymore on my k8s-master (arm) ! exiting in segfault...Doesn't help at all...!
    - I tried to do an `rpi-update`, didn't fix anything.
    - I changed iptables for the legacy one, didn't fix.
```
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```
    - I downloaded the manifest for weave network (from : `https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')")`, downgraded the version to 2.6.0 (from 2.7.0) then it started working!
- After that, realized I had DNS issues...
- Found out that one of the coredns pod was booted on my k8s-master (arm) and wasn't working properly!
  - I cordoned k8s-master, downscaled the deployment, re-scaled so both coredns are on my amd64 workers and it started working again!
- My opentsdb cluster doesn't seem to want to work anymore tho :( Problem with the namenode / datanode... I may have broken something with the docker kill I did behind the scene...? Not sure... But I don't think I'll keep this setup, I should go with Prometheus instead. I may still give it a full reset just to see it work again before thrashing it :P We'll see how I feel :) 
- I deleted and re-created the cluster

# helm uninstall opentsdb

# helm install opentsdb gradiant/opentsdb
  - All pods restarted on the same host... :( doesn't prove anything regarding my network, but it worked! Don't really know what was the issue but I guess I destroyed some data and I had mismatched IDs between datanode and namenode, something like that...
- My bosun container was also not running, scollector was unable to send its metrics. Restarting it fixed the issue! It also started on the same host tho... I'll delete the pod and cordon x3650 to force a restart on bigmonster.
  - Worked as expected, and collecting metrics still works, network seems happy :) 

## [2020 Oct 10] Thanksgiving week-end, fkn' covid, but 4 days w-e is good

Lots of stuff missing, I should back-document my Octopi setup, it's cool :)

Today, I started to monitor the temperature of my octopi RPIs with scollector.
- Configured scollector via command-line arguments and created a quick collector script
```
docker run -h octopi-tronxy -d -e SC_CONF_Host="192.168.2.120:30666" -e SC_CONF_ColDir="/opt/scollector/collectors" --privileged \
  --restart=always \
  --name scollector \
  -v /opt/scollector:/opt/scollector \
  sylvaintremblay/scollector-multiarch
```

```
#!/bin/ash
echo "{\"Metric\":\"rpi.temperature\",\"name\":\"rate\",\"value\":\"gauge\"}"
echo "{\"Metric\":\"rpi.temperature\",\"name\":\"unit\",\"value\":\"C\"}"
echo "{\"Metric\":\"rpi.temperature\",\"name\":\"desc\",\"value\":\"Temperature of the raspberry pi\"}"

echo "{\"Metric\":\"rpi.temperature\",\"timestamp\":$(date +%s),\"value\":$(echo "scale=2;$(cat /sys/class/thermal/thermal_zone0/temp) / 1000" | bc)}"
/opt/scollector/collectors/30 #  echo "scale=2;$(cat /sys/class/thermal/thermal_zone0/temp
) / 1000" |bc
40.78
```
The auto rate doesn't work tho, don't know why, may look into this later.

## [2020 Oct 10] Thanksgiving week-end, fkn' covid, but 4 days w-e is good

Got a new server this week-end!! Dell R820, mega monster! :P 

Setup for K8S
```
    1  apt install apt-transport-https ca-certificates curl software-properties-common
    3  apt update
    5  apt upgrade
    7  apt install gnupg-agent
    8  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    9  apt-key fingerprint 0EBFCD88
   10  sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   11     $(lsb_release -cs) \
   12     stable"
   13  apt update
   14  apt-get install docker-ce docker-ce-cli containerd.io
   15  sysctl net.bridge.bridge-nf-call-iptables=1
   20  usermod -aG docker stremblay
   26  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main"   | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
   27  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
   28  apt update
   29  apt-get install -y --allow-change-held-packages kubelet=1.18.0-00
   30  apt-get install -y --allow-change-held-packages kubectl=1.18.0-00
   31  apt-mark hold kubelet kubectl
   32  apt-get install -y --allow-change-held-packages kubeadm=1.18.0-00
   33  apt-mark hold kubeadm
   34  apt-get install kubernetes-cni
   35  vim /etc/fstab
   36  swapon --summary
   41  shutdown -r now
   42  sysctl net.bridge.bridge-nf-call-iptables
   44  vim /etc/hosts
   45  systemctl status kubelet

```

Then run the join command with my proper token
```
kubeadm join 192.168.2.122:6443 --token <token> --discovery-token-ca-cert-hash sha256:<xxx>

```

And it failed! :-(
```
W1013 19:44:09.693410    7259 join.go:346] [preflight] WARNING: JoinControlPane.controlPlane settings will be ignored when control-plane flag is not set.
[preflight] Running pre-flight checks
        [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
error execution phase kubelet-start: cannot get Node "r820": nodes "r820" is forbidden: User "system:bootstrap:kzxvfn" cannot get resource "nodes" in API group "" at the cluster scope
To see the stack trace of this error execute with --v=5 or higher
```

Looks like this is a problem with 1.18.0 ...!

Workaround : on my master :
```
sudo kubeadm init phase bootstrap-token
```
join command again and it worked this time!

## [2020 Oct 17] Week-end! Playing with the new r820

I hooked the r820 to WCG and gave it 60% of all CPUs, as expected, it produces more than twice what bigmonster can do, it's a beast!! :-D 

I'm running boinc like in docker directly for now (will probably create a pod for it at some point) 
```
docker run -d --name boinc --net=host --pid=host --cap-add SYS_PTRACE --security-opt apparmor:unconfined -v /opt/appdata/boinc/:/var/lib/boinc -e BOINC_GUI_RPC_PASSWORD=something -e BOINC_CMD_LINE_OPTIONS=--allow_remote_gui_rpc boinc/client
```
The `--cap-add` and `--security-opt` removed the apparmor error messages that were getting in my system logs every 10 seconds
```
[11879.936090] audit: type=1400 audit(1602891830.005:613845): apparmor="DENIED" operation="ptrace" profile="docker-default" pid=1813 comm="boinc" requested_mask="read" denied_mask="read" peer="unconfined"
```

I received my disks yesterday, 4 x [2.5" 600GB SAS 10K 6G](https://www.ebay.ca/itm/2-5-600GB-SAS-10K-6G-Hard-Drive-for-Dell-R610-R620-R630-R710-R720-R730-w-Tray/173137187910?_trkparms=aid%3D111001%26algo%3DREC.SEED%26ao%3D1%26asc%3D20160908105057%26meid%3D10f76d2b717c40f1b7e6f58633027a52%26pid%3D100675%26rk%3D2%26rkt%3D15%26mehot%3Dnone%26sd%3D193708624043%26itm%3D173137187910%26pmt%3D1%26noa%3D1%26pg%3D2380057%26brand%3DHGST&_trksid=p2380057.c100675.m4236&_trkparms=pageci%3A439ca471-1071-11eb-a518-fe6c847433a7%7Cparentrq%3A3674bcd71750ad32d240800cfffd343a%7Ciid%3A1), yeah! :-) hooked'em up, booted, lsblk, no disks... (kinda expected) Let's go in the bios! 

The disks are there, but I can't seem to find any way to set them in any kind of jbod mode, looks like I need to create a virtual disk. The controller is a PERC H710. After some research, I found out that my hypothesis was good, this card doesn't have any passthrough mode, it has to use it's hardware raid! And no ZFS with this, bad bad idea... You don't want to give an hardware raid-0 virtual disk to zfs, you want to give it direct access to the drive. So I created a RAID-6 with the disks for now, 1.2TB.

Then, I thought about my old `DELL Precision T7500` in which I have an unused card able to do JBOD. After verification, it's a `PERC H310`, which is about the only DELL controller able to do JBOD, woohoo :-) I think I'll try it instead of the H710, we'll see!

I changed the kubelet data folder to be on the new raid array, but I'll probably revert this to change the raid controller. I moved the data from `/var/lib/kubelet` into the new partition and symlinked the folder.

I'm happy with how my [usb ssd](https://www.amazon.ca/gp/product/B07838LHNV/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&psc=1) is performing on [usb2](https://www.amazon.ca/gp/product/B0868G1QCB/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&psc=1)! It's probably reading everything only once then it's all memory but still, it's doing the job quite well.

That was yesterday, don't know exactly what I'll do on the setup today, we'll see :P
