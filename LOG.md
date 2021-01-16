# Log / Journal

Here, I'll try to keep a journal of what I'm doing on the cluster to help my poor aging failing memory :P. I won't write everything in there tho, the git history and the *READMEs* are there for this reason! :)

## Cluster Description
- K8s: 1.18.0
- Docker: 19.3.8
- hybrid architecture (controller on *ARM*, nodes on *AMD64*)
- 1 controller and 3 nodes
- [Weave Net](https://www.weave.works/products/weave-net/) networking
- NFS Provisioner for persistent volumes
- CPUs: 96 cores
- Memory: 448GiB

## [2020 Mar 23]
The birth of the cluster!

#### BMs
##### Controller [k8s-master]
- Raspberry Pi 4B Rev 1.1
- *ARMv7 Processor rev 3 (v7l) @ 1.5GHz* [4 cores]
- 4GB Ram
- [120GB SSD] *Kingston ssdNOW uv300* via USB3 [ext4]
- Raspbian 10 [buster]

##### Node1 [bigmonster]
- Supermicro X9DAi/X9DAi custom build
- Dual CPU
- 2x *Intel(R) Xeon(R) CPU E5-2620 v2 @ 2.10GHz* [6 ht cores per cpu = 24 cores]
- 128GB Ram
- Root disk : [128GB SSD] *Crucial_CT128MX1* [ext4]
- Data disks : 4x [2TB SATA 5400RPM] *WDC WD20EFRX-68E (RED)* [raidz1-0]
- Ubuntu 18.04.4 LTS bionic

##### Node2 [x3650]
- IBM X3650 2U Server
- Dual CPU
- 2x *Intel(R) Xeon(R) CPU X5660 @ 2.80GHz* [6 ht core per cpu = 24 cores]
- 64GB Ram
- Root disk : [146GB SAS 10k] *IBM MBD2147RC* [ext4]
- Data disks : 5x [146GB SAS 15K] *Fujitsu MBE2147RC* [raidz1-0]
- Ubuntu 18.04.4 LTS bionic

##### Node3 [r820]
- Dell PowerEdge R820 2U Server
- Quad CPU (2 free sockets)
- 2x *Intel(R) Xeon(R) CPU E5-4657L v2 @ 2.40GHz* [12 ht core per cpu = 48 cores]
- 256GB Ram (max 3TB)
- Root disk : [60GiB M-Sata3 SSD on USB2] *TCSunBow* [ext4]
- Data disks : 4x [600GiB SAS 10K] *Hitachi HGST HUC109060CSS600* [raid6 on PERC H710]
- Ubuntu 20.04.1 LTS focal

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
  - `helm uninstall opentsdb`
  - `helm install opentsdb gradiant/opentsdb`
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

## [2020 Oct 12] New worker node in the cluster!! :-D

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

---

### Did some disk benchmarking using fio

#### R820 with mSATA disk on USB2
```
stremblay@r820:/var/lib/kubelet$ docker run --rm ljishen/fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75
Unable to find image 'ljishen/fio:latest' locally
latest: Pulling from ljishen/fio
5d20c808ce19: Pull complete
423e0bac337b: Pull complete
Digest: sha256:b2b4277c882e46e82358fcde3279ad2c98a7e535e693339df6ca4fd4b1addf3a
Status: Downloaded newer image for ljishen/fio:latest
test: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=64
fio-3.6
Starting 1 process
test: Laying out IO file (1 file / 4096MiB)

test: (groupid=0, jobs=1): err= 0: pid=55: Sat Oct 17 18:22:29 2020
   read: IOPS=668, BW=2675KiB/s (2739kB/s)(3070MiB/1175356msec)
   bw (  KiB/s): min=    8, max= 4464, per=100.00%, avg=2693.21, stdev=1628.12, samples=2333
   iops        : min=    2, max= 1116, avg=673.28, stdev=407.04, samples=2333
  write: IOPS=223, BW=894KiB/s (915kB/s)(1026MiB/1175356msec)
   bw (  KiB/s): min=    7, max= 1640, per=100.00%, avg=906.71, stdev=545.05, samples=2316
   iops        : min=    1, max=  410, avg=226.65, stdev=136.28, samples=2316
  cpu          : usr=0.95%, sys=4.66%, ctx=1048812, majf=0, minf=1904
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwts: total=785920,262656,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=2675KiB/s (2739kB/s), 2675KiB/s-2675KiB/s (2739kB/s-2739kB/s), io=3070MiB (3219MB), run=1175356-1175356msec
  WRITE: bw=894KiB/s (915kB/s), 894KiB/s-894KiB/s (915kB/s-915kB/s), io=1026MiB (1076MB), run=1175356-1175356msec
```

#### BigMonster root disk
```
stremblay@bigmonster:/$ docker run --rm ljishen/fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75
test: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=64
fio-3.6
Starting 1 process
test: Laying out IO file (1 file / 4096MiB)

test: (groupid=0, jobs=1): err= 0: pid=31: Sat Oct 17 18:05:53 2020
   read: IOPS=24.5k, BW=95.8MiB/s (101MB/s)(3070MiB/32030msec)
   bw (  KiB/s): min=21996, max=150768, per=99.90%, avg=98050.88, stdev=38221.21, samples=64
   iops        : min= 5499, max=37692, avg=24512.70, stdev=9555.27, samples=64
  write: IOPS=8200, BW=32.0MiB/s (33.6MB/s)(1026MiB/32030msec)
   bw (  KiB/s): min= 7185, max=51264, per=99.90%, avg=32769.53, stdev=12782.07, samples=64
   iops        : min= 1796, max=12816, avg=8192.31, stdev=3195.52, samples=64
  cpu          : usr=10.04%, sys=50.79%, ctx=20629, majf=0, minf=13
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwts: total=785920,262656,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=95.8MiB/s (101MB/s), 95.8MiB/s-95.8MiB/s (101MB/s-101MB/s), io=3070MiB (3219MB), run=32030-32030msec
  WRITE: bw=32.0MiB/s (33.6MB/s), 32.0MiB/s-32.0MiB/s (33.6MB/s-33.6MB/s), io=1026MiB (1076MB), run=32030-32030msec
```

#### BigMonster zfs pool
```
stremblay@bigmonster:/data$ docker run --rm ljishen/fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75
Unable to find image 'ljishen/fio:latest' locally
latest: Pulling from ljishen/fio
5d20c808ce19: Pull complete
423e0bac337b: Pull complete
Digest: sha256:b2b4277c882e46e82358fcde3279ad2c98a7e535e693339df6ca4fd4b1addf3a
Status: Downloaded newer image for ljishen/fio:latest
test: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=64
fio-3.6
Starting 1 process
test: Laying out IO file (1 file / 4096MiB)

test: (groupid=0, jobs=1): err= 0: pid=31: Sat Oct 17 18:02:52 2020
   read: IOPS=24.2k, BW=94.6MiB/s (99.2MB/s)(3070MiB/32444msec)
   bw (  KiB/s): min=22944, max=149144, per=100.00%, avg=97199.19, stdev=40322.60, samples=64
   iops        : min= 5736, max=37286, avg=24299.78, stdev=10080.65, samples=64
  write: IOPS=8095, BW=31.6MiB/s (33.2MB/s)(1026MiB/32444msec)
   bw (  KiB/s): min= 7168, max=50888, per=100.00%, avg=32481.13, stdev=13480.04, samples=64
   iops        : min= 1792, max=12722, avg=8120.25, stdev=3369.99, samples=64
  cpu          : usr=10.09%, sys=49.80%, ctx=18502, majf=0, minf=129
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwts: total=785920,262656,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=94.6MiB/s (99.2MB/s), 94.6MiB/s-94.6MiB/s (99.2MB/s-99.2MB/s), io=3070MiB (3219MB), run=32444-32444msec
  WRITE: bw=31.6MiB/s (33.2MB/s), 31.6MiB/s-31.6MiB/s (33.2MB/s-33.2MB/s), io=1026MiB (1076MB), run=32444-32444msec
```

#### t5810
```
stremblay@t5810:~$ docker run --rm ljishen/fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75
test: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=64
fio-3.6
Starting 1 process
test: Laying out IO file (1 file / 4096MiB)

test: (groupid=0, jobs=1): err= 0: pid=19: Sat Oct 17 17:58:50 2020
   read: IOPS=9602, BW=37.5MiB/s (39.3MB/s)(3070MiB/81845msec)
   bw (  KiB/s): min=   40, max=49392, per=100.00%, avg=38663.66, stdev=10168.71, samples=162
   iops        : min=   10, max=12348, avg=9665.88, stdev=2542.17, samples=162
  write: IOPS=3209, BW=12.5MiB/s (13.1MB/s)(1026MiB/81845msec)
   bw (  KiB/s): min=    8, max=16952, per=100.00%, avg=13002.73, stdev=3256.79, samples=161
   iops        : min=    2, max= 4238, avg=3250.65, stdev=814.19, samples=161
  cpu          : usr=4.88%, sys=15.18%, ctx=1086402, majf=0, minf=5
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.1%, >=64=0.0%
     issued rwts: total=785920,262656,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=37.5MiB/s (39.3MB/s), 37.5MiB/s-37.5MiB/s (39.3MB/s-39.3MB/s), io=3070MiB (3219MB), run=81845-81845msec
  WRITE: bw=12.5MiB/s (13.1MB/s), 12.5MiB/s-12.5MiB/s (13.1MB/s-13.1MB/s), io=1026MiB (1076MB), run=81845-81845msec
```

### Changed the Perc H710 for a Perc H310

Switched the card, immediately recognized, no issue. Went into the controller configuration, wiped the old raid config, switched the disks to `non-raid`, booted the system. It warned me about the card configuration change then booted without issue. Then, tada :
```
root@r820:/opt/MegaRAID/perccli# lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
loop0                       7:0    0    55M  1 loop /snap/core18/1880
loop1                       7:1    0  55.3M  1 loop /snap/core18/1885
loop2                       7:2    0  70.6M  1 loop /snap/lxd/16922
loop3                       7:3    0  30.3M  1 loop /snap/snapd/9279
loop4                       7:4    0    31M  1 loop /snap/snapd/9607
loop5                       7:5    0  71.3M  1 loop /snap/lxd/16099
sda                         8:0    0  55.9G  0 disk
├─sda1                      8:1    0     1M  0 part
├─sda2                      8:2    0     1G  0 part /boot
└─sda3                      8:3    0  54.9G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0  27.5G  0 lvm  /
sdb                         8:16   0 558.8G  0 disk
sdc                         8:32   0 558.8G  0 disk
sdd                         8:48   0 558.8G  0 disk
sde                         8:64   0 558.8G  0 disk
sr0                        11:0    1  1024M  0 rom
```

#### Perc H310 infos
```
root@r820:/opt/MegaRAID/perccli# !217
./perccli64 show
Status Code = 0
Status = Success
Description = None

Number of Controllers = 1
Host Name = r820
Operating System  = Linux5.4.0-51-generic

System Overview :
===============

----------------------------------------------------------------------------
Ctl Model           Ports PDs DGs DNOpt VDs VNOpt BBU  sPR DS EHS ASOs Hlth
----------------------------------------------------------------------------
  0 PERCH310Adapter     8   4   0     0   0     0 Msng On  3  N      0 Opt
----------------------------------------------------------------------------

Ctl=Controller Index|DGs=Drive groups|VDs=Virtual drives|Fld=Failed
PDs=Physical drives|DNOpt=DG NotOptimal|VNOpt=VD NotOptimal|Opt=Optimal
Msng=Missing|Dgd=Degraded|NdAtn=Need Attention|Unkwn=Unknown
sPR=Scheduled Patrol Read|DS=DimmerSwitch|EHS=Emergency Hot Spare
Y=Yes|N=No|ASOs=Advanced Software Options|BBU=Battery backup unit
Hlth=Health|Safe=Safe-mode boot
```

### ZFS Time!
Now that I have direct access to my physical drives, time for zfs :-)

```
# apt update
# apt install zfsutils-linux
root@r820:~# zfs --version
zfs-0.8.3-1ubuntu12.4
zfs-kmod-0.8.3-1ubuntu12.4


t@r820:~# zpool create datapool raidz /dev/sdb /dev/sdc /dev/sdd /dev/sde
invalid vdev specification
use '-f' to override the following errors:
/dev/sdb contains a filesystem of type 'LVM2_member'
/dev/sdd contains a filesystem of type 'LVM2_member'
/dev/sde contains a filesystem of type 'LVM2_member'
root@r820:~# zpool create -f datapool raidz /dev/sdb /dev/sdc /dev/sdd /dev/sde
root@r820:~# zpool list
NAME       SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
datapool  2.17T   209K  2.17T        -         -     0%     0%  1.00x    ONLINE  -
```
And here's our pool! Raidz1 is enough for my needs.

I'll create a LV for kubelet's data and symlink `/var/lib/kubelet` again.

---
### 21:20

I installed `rook-ceph` operator, it's almost magical, feels like cheating! hehe I don't have any disk or partition defined so no OSD (I think that's the right term but need to read more, ceph seems to be a whole world of its own!). After some reading, found out that zfs is not a good idea to use behind ceph. Partitions or raw block devices. I will try with r820 first, will destroy the zfs pool and partition the first sas disk to dedicate an empty partition and try to configure and use it. If it works, I'll partition all my disks in all the servers to give some space to ceph and zeep a zfs using as many disks as possible. 

Not tonight tho, it's dodo time!

## [2020 Oct 18] Experimenting with rook-ceph
Finally, I continued a little more yesterday night before going to sleep. 
- I destroyed my zfs pool on r820
- Created 100GB partitions to dedicate to CEPH on sdb and sdc
- Installed the provider
```
git clone --single-branch --branch v1.4.6 https://github.com/rook/rook.git
cp -rp rook/cluster/examples/kubernetes/ceph ~/k8s/operators/rook-ceph
cd ~/k8s/operators/rook-ceph
kubectl create -f common.yaml
kubectl create -f operator.yaml
kubectl create -f cluster.yaml
```
it worked like a charm, after 8 minutes, a ceph cluster on all my nodes!
```
stremblay@t5810:~/k8s/operators/rook-ceph$ kubectl -n rook-ceph get pods
NAME                                                   READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-2n9xm                                 3/3     Running     0          15h
csi-cephfsplugin-clwlb                                 3/3     Running     0          15h
csi-cephfsplugin-l82xg                                 3/3     Running     0          15h
csi-cephfsplugin-provisioner-58c4f6c77f-2zd8c          6/6     Running     0          15h
csi-cephfsplugin-provisioner-58c4f6c77f-wrq6n          6/6     Running     0          15h
csi-rbdplugin-8j95q                                    3/3     Running     0          15h
csi-rbdplugin-gqv9r                                    3/3     Running     0          15h
csi-rbdplugin-provisioner-5c8c987c97-b4tx4             6/6     Running     0          15h
csi-rbdplugin-provisioner-5c8c987c97-tqpd5             6/6     Running     0          15h
csi-rbdplugin-xtdq9                                    3/3     Running     0          15h
rook-ceph-crashcollector-bigmonster-868d76fdcd-b2t52   1/1     Running     0          15h
rook-ceph-crashcollector-r820-b96498c78-5chvv          1/1     Running     0          15h
rook-ceph-crashcollector-x3650-5cff7765d-jtlgz         1/1     Running     0          15h
rook-ceph-mgr-a-7f7d779d55-xbjrv                       1/1     Running     0          15h
rook-ceph-mon-a-75ccbb967f-9g7hs                       1/1     Running     0          15h
rook-ceph-mon-b-856cdff445-m7lx6                       1/1     Running     0          15h
rook-ceph-mon-c-8b7cd6fdc-w4rnj                        1/1     Running     0          15h
rook-ceph-operator-59fd69bfd4-zlmrz                    1/1     Running     0          15h
rook-ceph-osd-0-7bc45b584c-p7n5m                       1/1     Running     0          15m
rook-ceph-osd-1-8b4b86cb9-lh6zq                        1/1     Running     0          15m
rook-ceph-osd-prepare-bigmonster-98w28                 0/1     Completed   0          49m
rook-ceph-osd-prepare-r820-jx8sr                       0/1     Completed   0          14m
rook-ceph-osd-prepare-x3650-jmrkc                      0/1     Completed   0          49m
rook-ceph-tools-6f77f8564f-9mx4n                       1/1     Running     0          11h
rook-discover-b72fp                                    1/1     Running     0          15h
rook-discover-nbxlj                                    1/1     Running     0          15h
rook-discover-rmpph                                    1/1     Running     0          15h
```
But as expected, no OSD configured, no data disk / partition available. It will need a minimal configuration!

I looked into `cluster.yaml` and found the section requiring modifications. It did not work at first as I was probably too tired and unable to read, was badly setting options. This morning, I got it to work! :-) The logs for the creation of the OSDs are in the `rook-ceph-osd-prepare-<nodename>-<id>` container for each node. When you re-apply the config, a new instance of this pod restarts, configure, then complete.

How to configure:
```
  storage: # cluster level storage configuration and selection
    useAllNodes: false
    useAllDevices: false
    #deviceFilter:
    config:
      # metadataDevice: "md0" # specify a non-rotational storage so ceph-volume will use it as block db device of bluestore.
      # databaseSizeMB: "1024" # uncomment if the disks are smaller than 100 GB
      # journalSizeMB: "1024"  # uncomment if the disks are 20 GB or smaller
      # osdsPerDevice: "1" # this value can be overridden at the node or device level
      # encryptedDevice: "true" # the default value for this option is "false"
# Individual nodes and their config can be specified as well, but 'useAllNodes' above must be set to false. Then, only the named
# nodes below will be used as storage resources.  Each node's 'name' field should match their 'kubernetes.io/hostname' label.
    nodes:
    - name: "r820"
      devices: # specific devices to use for storage can be specified for each node
      - name: "sdb1"
      - name: "sdc1"
```

---
### 10:18

I did some move-around on x3650 to free the disks (backed-up data from the zfs pool, destroyed it, re-partitioned drives) then added sdb1 and sdc1 from x3650. The `osd-prepare` container started to crash-loop, I don't have the logs anymore but trying to create the OSD was crashing and exiting with an exception, something wasn't happy :( Then, the `osd-prepare` container disappeared and I had no clue on how to get it back. The operator log was continuously spitting 
```
Waiting on orchestration status update from 1 remaining nodes
```

I had the feeling something wasn't right with the partitions, did some searching and found the following [doc](https://rook.io/docs/rook/v1.4/ceph-teardown.html#zapping-devices) on cleaning the disks. I did the following on my disks :
```
# sgdisk --zap-all /dev/sdX
```

But I was still missing the `osd-prepare-x3650` container... I decided to reboot, just to see. The node disappearing kicked the operator in the ass and after it came back, all the containers went up properly, and the OSDs on x3650 have been successfully created, woohoo!! :-D
```
[root@rook-ceph-tools-6f77f8564f-9mx4n /]# ceph osd status
ID  HOST    USED  AVAIL  WR OPS  WR DATA  RD OPS  RD DATA  STATE
 0  r820   1064M  98.9G      0        0       0        0   exists,up
 1  r820   1064M  98.9G      0        0       0        0   exists,up
 2  x3650  1064M  98.9G      0        0       0        0   exists,up
```

Ceph is now up for real, I will be able to try to create a volume!

Thinking about it, I'm not sure I have the proper iSCSI packages installed on my nodes, need to check that first.

---
### 11:31

I searched about the iSCSI required packages and didn't found that back in the rook documentation pages... weird... anyway, let's don't care about this for now and try to use it!

I added the 2nd partition on x3650 to the OSDs so there's now 4. 

Found a really interesting [survival guide](https://www.cloudops.com/blog/the-ultimate-rook-and-ceph-survival-guide/), lots of infos which took me a long time to figure out is there, worth a read!

Then, it was time to try it! There's an example storage class definition
```
csi/rdb/storageclass.yaml
```
It needed a little modification first, change `spec.relicated.size` to `2` instead of `3` as I currently have OSDs only on 2 nodes. Then, `kubectl create -f storageclass.yaml`. Went fine.

Time for the real test now, create a PVC, see if it will work, then mount it in a pod. I used my classic `ubuntu` pod for this test.
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ubuntu-pv-claim
  labels:
    app: ubuntu
spec:
  storageClassName: rook-ceph-block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu
  labels:
    app: ubuntu
spec:
  hostname: ubuntu
  containers:
  - name: ubuntu
    image: ubuntu:latest
    command: ["/bin/bash", "-ec", "while :; do echo '.'; sleep 5 ; done"]
    volumeMounts:
    - name: ubuntu-persistent-storage
      mountPath: /data
  volumes:
  - name: ubuntu-persistent-storage
    persistentVolumeClaim:
      claimName: ubuntu-pv-claim
```
Worked like a charm!! :-D The PV is available in the POD! I created some files in the volume then cordoned the node where it was running and deleted the pod. Re-created it (on another node), it re-mounted the volume and the data was there! It works! :-)

I will have to do some data moving on bigmonster to re-partition the drives there and create other OSDs.

---
### 16:31

I migrated my data
- stoped kubelet on bigmonster
- unshared the zfs fs
- copied all the data from `/data/k8s-persistent-volumes` on the root disk
- tried to destroy the pool, was refusing, still in use, blabla, rebooted
- destroyed the pool
- moved the copied data folder to `/data/k8s-persistent-volumes`
- shared the folder
- the nfs provisioner container was trying to create on r820 and stuck in containercreating... I drained r820, it restarted successfully on bigmonster, I uncordoned r820.
- the nfs provisioner is back in shape, some opentsdb pods are still struggling but it's kinda usual, they'll probably stabilize by themselves... I'll let them some time, we'll see!

So I have freed my disks, I'll be able to create some OSDs on bigmonster too and have a real 3 replica setup!

---
### 17:30 Don't forget to install nfs tools on node!!
I was having issues with my opentsdb cluster unable to mount the nfs share for zookeeper... finally realized ubuntu server doesn't have nfs tools installed by default!
```
apt install nfs-kernel-server
```

## [2020 Dec 09] Fixing r820
Long time without update!

I started to get issues with r820, don't know exactly why (short on disk space I think). Kubelet was throwing errors about image not available for a container, blabla, then segfault... This started quite some time ago. At that time, I deleted the container (a rook-ceph container). Then it complained again about another one... did the same trick for 3-4 containers, then kubelet finally stoped spitting errors and the node status went back to Ready. Worked for a few minutes then same thing started to happen again. I remember seeing errors related to disk pressure and my root disk is quite small.

I then left that alone for a long time and looked back at it today.

Decided to move `/var/lib/docker` on another filesystem. I created a 100GB partition on each of my 4 disks and a ZFS pool on them. Moved all the content of `/var/lib/docker` there and created a symlink. Then when I tried to start docker it failed!

Looks like the overlay2 folder can't be on ZFS ! I copied it back on the rootfs and made symlinks for all other folders.

Then starting kubelet gave me the same container/image errors and segfault. Deleted the first container giving errors, restarted. Did it for a second one then kubelet restarted properly! After some time, everything was back alive, even my ceph cluster!

## [2021 Jan 16] Happy new year!
Have been sick like hell for the past few days but getting better now.

I started using my iPad for my training software instead of my t7500 workstation thus I got a new machine available! :-) It's:

- Dell precision T7500 Tower
- Dual W5580 @ 3.20 GHZ (16 cores total)
- 72GB Ram
- 4 ATA Disks (1TiB, 1TiB, 500GiB, 250GiB)

Enough for a cool node participating to the CEPH cluster! :-)

Did a classic docker installation (https://docs.docker.com/engine/install/ubuntu/)

Installed boinc, one more machine helping for COVID research!
