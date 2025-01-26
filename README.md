# The xrs444 HomeProd Environment

This repository contains (or will contain!) the Nix configurations for my HomeProd servers and workstations. It is very much a work in progress so don't expect it to work as expected, or to remain constant. this includes this Readme! :) 

Based loosely on configurations from Martin Wimpress, Jon Sager, and probably most of the other people Wimpress mentions, this environment provides the basis of a three-node K3s cluster.

The idea is to separate the services can computers I and my family use, and my lab environment I use for experimenting with work related systems. I'm using NixOS for the base of three servers, for all the usual reasons, and then running K3s on top to run the services in containers, which is better documented and more widely used. I'm also expanding it out to cover my own Macbook and my Wife and kids workstations. I work with a large Nutanix environment professionally, so a CE cluster will run alongside this for work-related fun.

Two of the servers also act as primary and secondary storage provided by ZFS arrays, and xsvr1 also runs VMs for HomeAssistant and a TP-Link Omada controller. This may move to K3s later.

Each server has a 1TB boot SSD, and for xsvr 1 and 2, this is a Raid1 array, as well as a 1TB SSD for k3s Longhorn storage.

Servers and roles:

| Server | CPU | Motherboard | RAM | ZFS Storage Array | Extra |
|--------|-----|-------------|-----|-------------------|-------|
| xsvr1 | Ryzen 7 | SuperMicro | GB | 6 X 3TB ( 3 R1 VDEVs) | HomeAssistant and Omada VMs |
| xsvr2 | Intel Atom C2750 | SuperMicro| 32 GB | 4 X 2TB ZRAID2 | |
| xsvr3 | Intel i5 | Lenovo m920x | 16 GB | N/A | |

