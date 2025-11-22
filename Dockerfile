FROM ubuntu:jammy
RUN apt-get update
RUN apt-get install -y sudo vim curl wget net-tools iputils-ping man-db less procps
RUN apt-get install -y build-essential git python3 python3-pip
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
