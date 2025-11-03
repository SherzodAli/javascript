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

## Docker (interacting with containers)

### Docker images raw

- images got from [Docker Hub](https://hub.docker.com) (like npm registry)

```bash
# start docker contaier with docker running in it connected to host docker daemon
# we need it to then chroot and show that docker simply does Chroot, Namespaces, Cgroups
docker run -ti -v /var/run/docker.sock:/var/run/docker.sock --privileged --rm --name docker-host docker:26.0.1-cli

# -d for detach (container is running and not exitted)
# docker kill my-alpine OR docker attach my-alpine (attaches to the current process)
docker run --rm -dit --name my-alpine alpine:3.19.1 sh
docker export -o dockercontainer.tar my-alpine

mkdir container-root
tar xf dockercontainer.tar -C container-root/

chroot container-root

# make a contained user, mount in name spaces
unshare --mount --uts --ipc --net --pid --fork --user --map-root-user chroot $PWD/container-root ash # this also does chroot for us
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /tmp

# here's where you'd do all the cgroup rules making with the settings you wanted to
```

### Docker images with Docker

```bash
# --interactive or -i; --tty or -t
# `alpine` without specifying tag/version, puts `latest` by default
docker run --interactive --tty alpine
docker run -it alpine ls # does `ls` and stops
docker run -dit alpine # detaches, keeps running in background

docker start/stop $CONTAINER_NAME # or hash | short hash
docker kill $CONTAINER_NAME # stop gracefully stops (10sec max), kill stops forcefully
docker rm $CONTAINER_NAME

docker exec -it $CONTAINER_NAME sh
docker attach $CONTAINER_NAME

docker ps -a # list all containers (-a)
docker container prune # remove all stopped containers

docker image ls
docker rmi $IMAGE_NAMES... # or hash

# Node
docker run -it --rm node:20
docker run -it --rm python:3.9.0
docker run -it --rm node:20 cat /etc/issue
docker run -it --rm denoland/deno:centos
docker run -it --rm golang:1.22.2
```

### Tags & Docker CLI

```bash
docker history node:20
docker top $CONTAINER_NAME

docker info
docker search python # seaches keyword `python`
```

## Dockerfiles (building containers)

### Dockerfile

```dockerfile
FROM node:20

# There're some things which run when building, others when executing
# CMD runs only when executing
CMD ["node", "-e", "console.log(\"Hello there\")"]
```

```bash
docker build .
docker build . -t my-node-app # or --tag
docker build . -t my-node-app:1
```

### Node.js app

```dockerfile
FROM node:20

COPY index.js index.js

CMD ["node", "index.js"]
```

```js
const http = require("http");

http
  .createServer(function (request, response) {
    console.log("request received");
    response.end("omg hi", "utf-8");
  })
  .listen(3004);
console.log("server started");
```

```bash
docker build . -t node-app:1
docker run --init node-app:1 # init let's you CTRL-C to kill the process
docker run --init --rm --publish 3003:3004 node-app:1 # 3004 is container, 3003 is host
```

### Organizing files

```dockerfile
FROM node:20

# `node` user is precreated by node image (and it's running processes)
RUN useradd -ms /bin/bash sherzod

USER sherzod

# cd to that directory
WORKDIR /home/sherzod/code

# used COPY not ADD, because ADD has additional logic
# like adding remote urls, unzipping files, etc. which almost never you need
COPY --chown=sherzod index.js .

CMD ["node", "index.js"]
```

### Adding dependencies

```js
const fastify = require("fastify")({ logger: true });

fastify.get("/", function handler(request, reply) {
  reply.send({ hello: "world" });
});

// host 0.0.0.0 is important, otherwise specifying localhost causes errors
// localhost is container itself
fastify.listen({ port: 8080, host: "0.0.0.0" }, (err) => {});
```

```dockerfile
FROM node:20

USER node

WORKDIR /home/node/code

COPY --chown=node . .

# clear install, removes node_modules and installs 
RUN npm ci

CMD ["node", "index.js"]
```

```bash
docker build -t node-app:2 .
docker run --init --rm -p 8080:8080 --name na node-app:2
```

### Layers

- If anything is changed in Dockerfile, docker will run it and commands below (everything above is cached)
- So don't put installing packages after full codebase copyi (if one file is changed, it will again run npm install)
    (better put package.lock and npm install first and then copy codebase)

```dockerfile
FROM node:20

USER node

WORKDIR /home/node/code

COPY --chown=node:node package*.json .

RUN npm ci

COPY --chown=node . .

CMD ["node", "index.js"]
```

## Making tiny containers

### Alpine

- Alpine is built on top of Busybox
- Busybox: "we wanna have the least amount of stuff possible and still be considered as linux distribution"
- use `FROM node:20-alpine` (from 1.1GB to 150MB)
- Alpine is last mile. Use full fat distro for development and when shipping, use Alpine

- To go even smaller, add `FROM alpine-3.19.1` and `RUN apk add --update nodejs npm`
    and `RUN addgroup -S node && adduser -S node -G node`

### Multi-stage builds

- Does your app need npm? No, just use it for build step and ship only what's needed
- usually you cut a bunch, since you cut native dependencies which your app doesn't need
- If your app needs to connect to some server, get secrets, etc., you can do this in build step

```dockerfile
# cost of node:20 is paid once and cached forever, so no need to use alpine
FROM node:20 AS node-builder
WORKDIR /builder
COPY package*.json .
RUN npm ci
COPY . .

FROM alpine:3.19
RUN apk add --update nodejs
RUN addgroup -S node && adduser -S node -G node
USER node
WORKDIR /home/node/code
COPY --from=node-builder --chown=node:node /builder .
CMD ["node", "index.js"]
```

### Distroless

- Alpine uses `musl` instead of `glibc` which causes problems with kubernetes (DNS problem)
    also many languages rely on native C deps, and when using alpine, and you try to build, it'll be long

- Other options
    - [Google's Distroless](gcr.io/distroless/base) - 30MB
    - [Distroless Nodejs](gcr.io/distroless/nodejs) - 30MB
    - [Debian Slim](debian:bookworm-slim) - 100MB
    - [Red Hat Univeral Base Image Micro](registry.access.redhat.com/ubi9-micro) - 24MB
    - [Wolfi open source](cgr.dev/chainguard/wolfi-base:latest) - 15MB

### Static asset project

- Astro project, builds to /dist folder
- Run on `-p 8080:80`, since nginx runs on 80 by default (to change it, need to run as root, which is not good)
- not doing `CMD`, because `nginx` already does it
- copying only files needed to run app (only `/dist` folder)

```dockerfile
FROM node:20 AS node-builder
WORKDIR /app
COPY . .
RUN npm ci
RUN npm run build

# you could totally use nginx:alpine here too
FROM nginx:latest
COPY --from=node-builder /app/dist /usr/share/nginx/html
```

- `docker scout quickview $IMAGE_NAME` - quick scan for security volnerabilities
- `docker scout cves $IMAGE_NAME` - view [c]ommon [v]ulnerabilities and [e]xposures

## Docker features

- We already learned everything about containers, they're not more complicated than that
- Other features are on top of containers
    - how we give files to containers
    - network with containers
    - use containers for development

### Bind mounts

- I want to use my local files through container
    (portal to a local computer translated directly into a container, no need to rebuild every time)

- Spinning up nginx quickly (serving local static assets)
    (yes, can use use `npx serve`, but what if you're testing nginx configuration,
    since you can bind mount configuration as well)

```bash
# from the root directory of your Astro app
docker run --mount type=bind,source="$(pwd)"/dist,target=/usr/share/nginx/html -p 8080:80 nginx:latest
```

### Volumes

- It's for state which needs to survive between runs and can be shared across all docker containers
- e.g. you have db, don't want to loose data when container is gone

```js
const fs = require("fs").promises;
const path = require("path");

const dataPath = path.join(process.env.DATA_PATH || "./data.txt");

fs.readFile(dataPath)
  .then((buffer) => {
    const data = buffer.toString();
    console.log(data);
    writeTo(+data + 1);
  })
  .catch((e) => {
    console.log("file not found, writing '0' to a new file");
    writeTo(0);
  });

const writeTo = (data) => {
  fs.writeFile(dataPath, data.toString()).catch(console.error);
};
```

```dockerfile
FROM node:20-alpine
COPY --chown=node:node . /src
WORKDIR /src
CMD ["node", "index.js"]
```

```bash
docker build -t incrementor .
docker run --rm incrementor

docker run --rm --env DATA_PATH=/data/num.txt --mount type=volume,src=incrementor-data,target=/data incrementor

docker volume ls
docker volume rm incrementor-data
docker volume help # create, inspect, etc.
```

### Dev Containers

- your project is opened in a container (works in VS Code, neovim, IDEs)
    - no need to intall ruby, etc., everthing just works
    - can install automatically correct vs code extensions (pylance, etc.)
- DevContainer CLI
- Github Codespaces - will automatically open a dev container
- Your dev container won't be the same as production container
- It's okay that your project has multiple Dockerfiles

### Networking

- Your DB and App should be in different containers (to scale them properly)
    and to communicate they should share network
- If you have a lot of containers working with network -
    use some sort of orchestration (docker compose, k8s)

```js
const fastify = require("fastify")({ logger: true });
const { MongoClient } = require("mongodb");
const url = process.env.MONGO_CONNECTION_STRING || "mongodb://localhost:27017";
const dbName = "dockerApp";
const collectionName = "count";

async function start() {
  const client = await MongoClient.connect(url);
  const db = client.db(dbName);
  const collection = db.collection(collectionName);

  fastify.get("/", async function handler(request, reply) {
    const count = await collection.countDocuments();
    return { success: true, count };
  });

  fastify.get("/add", async function handler(request, reply) {
    const res = await collection.insertOne({});
    return { acknowledged: res.acknowledged };
  });

  fastify.listen({ port: 8080, host: "0.0.0.0" }, (err) => {
    if (err) {
      fastify.log.error(err);
      process.exit(1);
    }
  });
}

start().catch((err) => {
  console.log(err);
  process.exit(1);
});
```

```dockerfile
FROM node:20-alpine
COPY . .
RUN npm ci
CMD ["node", "index.js"]
```

```bash
docker network ls
docker network rm $NETWORK_NAME

# don't use bridge, since all containers using default 'bridge' driver
# will see each other (Docker doesn't recommend it)
docker network create --driver=bridge app-net

docker run -d --network=app-net -p 27017:27017 --name=mongo-db-test mongo:7

docker build -t app-mong .
docker run -p 8080:8080 --network=app-net --rm --env MONGO_CONNECTION_STRING=mongodb://mongo-db-test:27017 app-mong
```

## Multi-container projects

### Docker compose

- Docker compose is excellent at development. In production can be used,
    but only if up to ~5 containers (not complicated, or need features like scale to 0, clusters - then neeed kubernetes)
- docker-compose with dash is v1, without it is v2 (almost the same)

[Project Repo](https://github.com/btholt/project-files-for-complete-intro-to-containers-v2/tree/main/docker-compose/web)

```bash
├── docker-compose.yml
├── api
│   ├── Dockerfile
│   ├── index.js
│   ├── package-lock.json
│   └── package.json
└── web
    ├── dist
    │   ├── env.js
    │   └── index.html
    ├── Dockerfile
    ├── package-lock.json
    ├── package.json
    └── src
        ├── index.html
        ├── style.css
        └── web.jsx
```

```js
// api/index.js
const cors = require("@fastify/cors");
const fastify = require("fastify")({ logger: true });
const { MongoClient } = require("mongodb");
const url = process.env.MONGO_CONNECTION_STRING || "mongodb://localhost:27017";
const dbName = "dockerApp";
const collectionName = "count";

async function start() {
  await fastify.register(cors, {origin: "*"});

  const client = await MongoClient.connect(url);
  const db = client.db(dbName);
  const collection = db.collection(collectionName);

  fastify.get("/", async function handler(request, reply) {
    const count = await collection.countDocuments();
    return { success: true, count };
  });

  fastify.get("/add", async function handler(request, reply) {
    const res = await collection.insertOne({});
    return { acknowledged: res.acknowledged };
  });

  fastify.listen({ port: 8080, host: "0.0.0.0" }, (err) => {});
}

start().catch((err) => {});
```

```dockerfile
# api/Dockerfile
FROM node:20
USER node
RUN mkdir /home/node/code
WORKDIR /home/node/code
COPY --chown=node:node package-lock.json package.json ./
RUN npm ci
COPY --chown=node:node . .
CMD ["node", "index.js"]
```

```js
// web/dist/env.js
window.API_URL = "http://api:8080";
```

```js
// web/src/web.jsx
import { createRoot, useState } from "react-dom/client";
import { useState, useEffect } from "react";

const API_URL = process.env.API_URL || "http://localhost:8080";

console.log("API_URL", API_URL);
console.log("env", process.env.API_URL);
console.log("node_env", process.env.NODE_ENV);

function App() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    getCount().then((res) => setCount(res.count));
  }, []);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => addToCount().then(() => getCount().then((res) => setCount(res.count)))}>
        Add Record to Count Database
      </button>
    </div>
  );
}

function getCount() {
  return fetch(API_URL).then((res) => res.json());
}

async function addToCount() {
  return fetch(`${API_URL}/add`).then((res) => res.json());
}

const root = createRoot(document.getElementById("target"));
root.render(<App />);
```

```dockerfile
# web/Dockerfile
FROM node:20 AS node-builder
WORKDIR /app
COPY . .
RUN npm ci
RUN npm run build

FROM nginx:1.25-alpine
COPY --from=node-builder /app/dist /usr/share/nginx/html
```

```yaml
# docker compose
services:
  api:
    build: api # api directory (knows where to find Dockefile)
    ports:
      - "8080:8080"
    links:
      - db # make db service available, so they can talk with each other on the network
    environment:
      MONGO_CONNECTION_STRING: mongodb://db:27017
  db:
    image: mongo:7
  web:
    build: web
    environment:
      API_URL: http://api:8080
    ports:
      - "8081:80"
```

`docker compose up --build` - without `build` it will run thinking you already built it
`docker compose up --scale web=10` - creates 10 web containers (should write program to handle multiple ips)

### Kubernetes

- It's built for Google scale stuff (where containers and what we used already is for individual developers, containers)
- It consists of
    - **Control plane** - brain of your cluster, decides whom to kill, whom to create
    - **Nodes** - worker servers (VPS), that run actual containers/Pods (№ depends on container's demand of resources)
    - **Pod** - 1 pod is like a VM which can run 1 or multiple actual containers
    - **Service** - group of pods which make up one backend
    - **Deployment** - description into what your cluster should look like (and control plane will keep your cluster such)
- CLI: `kubectl` (local kubernet - minikube or Docker desktop kubernetes)
    `kubectl config use-context minikube/docker-desktop`
    `kubectl config use aws` - shortened as `use`. Can use Azure AKS, Amazon EKS, Google GKE

```bash
brew install kubectl

kubectl cluster-info
```

### Kompose

- Kompose converts your docker-compose file to k8s configuration

[Project Code](https://github.com/btholt/project-files-for-complete-intro-to-containers-v2/tree/main/kubernetes)
Same as above, but with some minor changes

```bash
├── docker-compose.yml
├── api
│   ├── Dockerfile
│   ├── index.js
│   ├── package-lock.json
│   └── package.json
└── web
    ├── dist
    │   ├── env.js
    │   └── index.html
    ├── Dockerfile
    ├── nginx.conf
    ├── package-lock.json
    ├── package.json
    └── src
        ├── index.html
        ├── style.css
        └── web.jsx
```

```nginx
  listen 80;

  server_name web;

  location / {
    root /usr/share/nginx/html;
    try_files $uri /index.html;
  }

  location /api {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-NginX-Proxy true;
    proxy_pass http://api:8080;
    proxy_ssl_session_reuse off;
    proxy_set_header Host $http_host;
    proxy_cache_bypass $http_upgrade;
    proxy_redirect off;
  }
}
```

```dockerfile
# web/Dockerfile
FROM node:20 AS node-builder
WORKDIR /app
COPY . .
RUN npm ci
ENV API_URL=http://localhost:8081/api
RUN npm run build

FROM nginx:1.25-alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=node-builder /app/dist /usr/share/nginx/html
```

```diff
// web/src/web.jsx
-const API_URL = process.env.API_URL || "http://localhost:8080";
+const API_URL = process.env.API_URL || "http://localhost:8080/api";
```

```bash
brew install kompose

kompose convert --build local
kubectl apply -f '*.yaml'

kubectl get all
kubectl cluster-info
kubectl cluster-info dump

# Scale
kubectl scale --replicas=5 deployment/api
kubectl delete all --all
```

### Docker alternatives

- Container builders (docker build)
    - [Buildah](https://buildah.io/) - Reads Dockerfiles; builds using host package managers; Red Hat-supported.
- Container runtime tools (docker run)
    - [Podman](podman.io) - docker relies on having daemon, podman doesn't. Has Podman Compose
    - [Colima](https://github.com/abiosoft/colima) - Simplifies Docker setup on macOS/Linux using existing tools
    - [rkt] - Deprecated CoreOS container project, no longer maintained
- Container runtimes (actual code executing containers)
    - [containerd](https://containerd.io) - CNCF project; Docker’s core runtime layer.
    - [gVisor](https://gvisor.dev) - Google’s secure container runtime emphasizing isolation.
    - [Kata](https://katacontainers.io) - Uses lightweight VMs for strong container separation.
- Container orchestrators (alternatives to Kubernetes, and somewhat to docker compose)
    - [Apache Mesos](https://mesos.apache.org) - Complex, older than Kubernetes, still minimally maintained.
    - [Docker Swarm](https://docs.docker.com/engine/swarm/) - Docker’s simpler orchestration, mostly replaced by Kubernetes.
    - [OpenShift](https://www.openshift.com) - Red Hat’s Kubernetes platform with built-in CI/CD.
    - [Nomad](https://www.nomadproject.io) - HashiCorp’s lightweight, developer-friendly orchestrator alternative.
    - [Rancher](https://www.rancher.com) - SUSE’s Kubernetes manager with added features.
- Desktop apps (alternatives to Docker Desktop)
    - [Podman Desktop](https://podman-desktop.io) - Red Hat’s GUI for Podman and Buildah containers.
    - [Rancher Desktop](https://rancherdesktop.io) - SUSE’s Docker-compatible desktop for container management.
- Secrets
    - Docker secrets (with docker swarm?)
    - Hashicorp vault
    - Azure keyvault
