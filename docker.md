# Docker

## Intro

- Container is 3 features
    1. Jailing the process (like virtual machines)
    2. Namespaces
    3. Cgroups (Control groups)
- History: Bare Metal -> Virtual Machines -> Public Cloud (VPS) -> Containers
- Containers info
    - you are running copy of something, but not a full copy of it
    - you don't have the whole cost of running the whole thing
    - strong security boundaries (not as strong as VMs)

### Chroot (change root)

```bash
docker ps # list all containers

# docker run - run an instance of the container
# --it - make this interactive, don't just throw it in the background process (I want to interact with it directly)
# --name docker-host - giving container a name, otherwise it will a random generated name
# --rm - whenever I stop this container, throw everything away (don't keep the logs, all that stuff)
# --privileged - normally, you don't want to do privileged, but because we are creating many things by hand, we want to give root privileges
# ubuntu:jammy - ubuntu - distribution name, jammy - the actual version we will run
docker run --it --name docker-host --rm --privileged ubuntu:jammy
```

```bash
cat /etc/issue # see OS system version on linux
cat # open a file and read it for me

mkdir /my-new-root

# it will fail. It will change root, but since it can see only from itself and deeper, 
# it cannot even see bash (need to bring it ourselves, can ignore all deps with no path printed)
chroot /my-new-root bash

ldd /bin/bash # list required libraries to run /bin/bash (like dll's on Windows)
mkdir /my-new-root/lib{,64} /my-new-root/bin # or `mkdir /my-new-root/lib /my-new-root/lib64`
cp /bin/bash /my-new-root/bin && 
    cp /lib/aarch64-linux-gnu/libtinfo.so.6 my-new-root/lib && 
    cp /lib/aarch64-linux-gnu/libc.so.6 my-new-root/lib && 
    cp /lib/ld-linux-aarch64.so.1 my-new-root/lib

chroot /my-new-root bash

cp /bin/ls my-new-root/bin/ && 
    cp /lib/aarch64-linux-gnu/libselinux.so.1 \
       /lib/aarch64-linux-gnu/libc.so.6 \
       /lib/ld-linux-aarch64.so.1 \ 
       /lib/aarch64-linux-gnu/libpcre2-8.so.0 \
       my-new-root/lib

cp /bin/cat my-new-root/bin/ && cp /lib/aarch64-linux-gnu/libc.so.6 /lib/ld-linux-aarch64.so.1 my-new-root/lib`
```

### Namespaces

**Namespaces** allow you to hide processes from other processes

After commands below all processes and resources were isolated
    (ps aux from host and unshared environment, aka container, contained process)

```bash
ps aux # list all processes

chroot /my-new-root bash
docker exec -it docker-host bash # connects to the container

apt-get update -y
apt-get install debootstrap -y # tool to install minimal version of Debian

# if you don't specify `--variant=minbase`, it will install the full copy, which is bigger
debootstrap --variant=minbase jammy /better-root # (-150MB)

# create new process, and inside create new namespaces for 
# uts (unix time sharing), network, process ids, process forkings, user spaces
unshare --mount --uts --ipc --net --pid --fork --user --map-root-user 

chroot /better-root bash
mount -t proc none /proc # tells linux there's a system to use, process namespaces
mount -t sysfs none /sys # filesystem
mount -t tmpfs none /tmp # filesystem

tail -f /my-new-root &` - from host (to create a process)
```

### Cgroups

**Cgroups (control groups)** - methodology of isolating resources, computing resources available to individual process trees

cgroup v2 is now the standard.

```bash
# should get 0 or 1, if more, you're on cgroup v1 (need to upgrade OS)
grep -c cgroups /proc/mounts

cd /sys/fs/cgroup && ls && cat cpu.max
mkdir sandbox && cd sandbox

# 8578 (ps aux first `bash` pid after unshare)
echo 8578 > /sys/fs/cgroup/sandbox/cgroup.procs 
# it will show all pids, except 8578, because process can belong only to one cgroup
cat /sys/fs/cgroup/cgroup.procs 

mkdir /sys/fs/cgroup/other-procs
echo 8578 > /sys/fs/cgroup/other-procs/cgroup.procs # move all processes

# add the controllers, plus means add these. Only enable those controllers which are listed in cgroup.controllers 
# echo "+cpuset +cpu +io +memory +pids" > /sys/fs/cgroup/cgroup.subtree_control
# (you cannot do this if you have any processes, therefore we moved them)
echo "+cpuset +cpu +io +memory +hugetlb +pids +rdma" > /sys/fs/cgroup/cgroup.subtree_control

# now we have all controllers listed, because we made controllers available to child control groups
ls sandbox 
```

### Limiting resources with Cgroup

> Container is just change root, namespaces, cgroups

```bash
apt-get install htop -y # visualizes all processes, how RAM is being used

# run this from #1 terminal and watch it in htop to see it consume about a gig of RAM and 100% of CPU core
yes | tr \\n x | head -c 1048576000 | grep n

cat /sys/fs/cgroup/sandbox/memory.max # should see max, so the memory is unlimited
echo 83886080 > /sys/fs/cgroup/sandbox/memory.max # set the limit to 80MB of RAM (the number is 80MB in bytes)
yes | tr \\n x | head -c 1048576000 | grep n # now RAM is limited, CPU usage is limited as well

yes /dev/null # taking 100% CPU (spamming yes)
echo '5000 100000' > /sys/fs/cgroup/sandbox/cpu.max # giving CPU 5%

# fork bomb
fork() {
    fork | fork &
}
fork

# but you'll see it written as this
# where : is the name of the function instead of fork
:(){ :|:& };:

# limit max processes cgroup can run at a time
echo 3 > /sys/fs/cgroup/sandbox/pids.max

# this runs 5 15 second processes that run and then stop. run this from within 
# #2 and watch it work. now run it in #1 and watch it not be able to. it will have to retry several times
for a in $(seq 1 5); do sleep 15 & done 
```
