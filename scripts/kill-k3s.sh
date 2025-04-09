systemctl stop k3s
rm -rf /etc/rancher/k3s/
rm -rf /etc/rancher/node/
rm -rf /var/lib/rancher/k3s/
nixos-rebuild switch