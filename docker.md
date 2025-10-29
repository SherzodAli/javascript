# Docker

## Structure

- Crafting containers by hand
    - what are containers
    - chroot
    - namespaces
    - cgroups
- Docker
    - docker images
    - docker images with docker
    - javascript on docker
    - tags
    - docker cli
- Dockerfiles
    - intro
    - build a node.js app
    - expose
    - layers
- Making tiny containers
    - alpine linux
    - multi stage builds
    - distroless
    - static asset project
- Docker features
    - bind mounts
    - volumes
    - dev containers
    - networking with docker
- Multi container projects
    - docker compose
    - kubernetes
    - kompose
- Docker alternatives

## Crafting containers by hand

- Container is combination of isolation + resource control
    - chroot / jail → isolates filesystem view - `chroot /mnt/ubuntu /bin/bash`
    - namespaces → isolate system resources like PID, network, UTS, mount, user, etc.
    - cgroups (resource control) → limit and account for CPU, memory, I/O, etc.
- Why containers
    - Isolation – each app runs in its own environment → no dependency conflicts.
    - Consistency – fixes “it works on my machine” by packaging app + deps.
    - Efficiency – shares host OS kernel → lighter and faster than VMs (start in ms).
    - Scalability & orchestration – easily deployed, replicated, and managed (e.g., Kubernetes).

### Chroot

```bash
docker run -it --name docker-host --rm --privileged ubuntu:jammy
docker exec -it docker-host bash

cat /etc/issue # view linux version
uname -a # even more info
hostnamectl set-hostname smartenergy-gateway

# changed root to a new folder, but there is no bash and /bin folder
chroot /my-new-root bash

# shows all dependencies (DLLs on windows) of bash
# then need to copy all which have paths to new root folder
ldd /bin/bash

cp /bin/bash /my-new-root/bin/bash
cp /lib/dep1 /lib/dep2 /my-new-root/lib
cp -r /lib /my-new-root # or just copy all deps
```

### Namespaces

```bash
apt-get update -y
apt-get install debootstrap -y
debootstrap --variant=minbase jammy /new-root # installs 150MB each time you run it

# head into the new namespace'd, chroot'd environment
unshare --mount --uts --ipc --net --pid --fork --user --map-root-user chroot /new-root bash # this also chroot's for us
mount -t proc none /proc # process namespace
mount -t sysfs none /sys # filesystem
mount -t tmpfs none /tmp # filesystem
```

### Cgroups

```bash
cd /sys/fs/cgroups

mkdir sandbox # automatically creates files

ps aux # grep PID of bash below unshare (we need to add it to sandbox pids)
echo $PID > sandbox/cgroup.procs

# we need to activate cgroup.subtree_controller, but we can't until there any active processes
mkdir other-procs 
echo $EACH_PID > other-procs/cgroup.procs # cat cgroup.procs

# add the controllers (some may cause errors, delete them)
echo "+cpuset +cpu +io +memory +hugetlb +pids +rdma" > /sys/fs/cgroup/cgroup.subtree_control
ls sandox # now there much more

apt-get install htop -y

# inside #1 / the cgroup/unshare – this will peg one core of a CPU at 100% of the resources available, see it peg 1 CPU
yes > /dev/null

# from #2 this allows the cgroup to only use 5% of a CPU
echo '5000 100000' > /sys/fs/cgroup/sandbox/cpu.max
```
