# The xrs444 HomeProd Environment

This repository contains (or will contain!) the Nix configurations for my HomeProd servers and workstations. It is very much a work in progress so don't expect it to work as expected, or to remain constant. this includes this Readme! :)

Based loosely on configurations from Martin Wimpress, Jon Sager, and probably most of the other people Wimpress mentions, this environment provides the basis of a three-node Talos K8s cluster.

The idea is to separate the services can computers I and my family use, and my lab environment I use for experimenting with work related systems. I'm using NixOS for the base of three servers, for all the usual reasons, and then running Talos VMs on top to run the services in containers, which is better documented and more widely used. I'm also expanding it out to cover my own Macbook and my Wife and kids workstations. I work with a large Nutanix environment professionally, so a CE cluster will run alongside this for work-related fun.

Two of the servers also act as primary and secondary storage provided by ZFS arrays, and xsvr1 also runs VMs for HomeAssistant and a TP-Link Omada controller. This may move to K8s later.

Each server has a 1TB boot SSD, and for xsvr 1 and 2, this is a Raid1 array, as well as a 1TB SSD for k3s Longhorn storage.

## Servers and roles:

| Server | CPU | Motherboard | RAM | ZFS Storage Array | Extra |
|--------|-----|-------------|-----|-------------------|-------|
| xsvr1 | Ryzen 7 | SuperMicro | GB | 6 X 3TB ( 3 R1 VDEVs) | HomeAssistant and Omada VMs |
| xsvr2 | Intel Atom C2750 | SuperMicro| 32 GB | 4 X 2TB ZRAID2 | |
| xsvr3 | Intel i5 | Lenovo m920x | 16 GB | N/A | |

## Network:

Linking this all together is a pair of Brocade 7250s in a stack, with each server having a pair of 10G connections shared between the two, using LACP. the Homelab uses a 6610 fed from this switch and routing and firewall duties are performed by a Firewalla Pro. Wifi and endpoint switching is handled with TP-Link Omada gear.

*** To do:

- Decide if xdt2-g and xdt3-r will use NixOS or Bazzite with Ansible. Decisions decisions!
- Get minimal images working for rollout to SBC devices
- Configure logins with Kanidm
- Configure some form of home dir backup
- Some sort of access route for shared folders for ingest/access
- Check ZFS replication and configure offsite
- Configure Prometheus/Graphana for dashboard and alerts
- Set up Ntfy for alerts
- Configure Atuin for users
- Get build sorted for xcomm1 - tries to build the universe!
- 
