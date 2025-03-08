{ pkgs, lib, ... }:

let
  vmSpecs = [
    {
      name = "v-xhac1";
      vcpu = "2";
      memory = "8";
      hostNic = "bridge17";
      mac = "52:54:00:00:00:01";
      autostart = true;
      storage = {
        path = "/vm/v-xhac1/v-xhac1.qcow2";  # Path to existing image
        type = "qcow2";  # Image format
        device = "disk";
      };
    }
    {
      name = "v-xpbx1";
      vcpu = "2";
      memory = "6";
      hostNic = "bridge16";
      mac = "52:54:00:c7:8c:08";
      autostart = true;
      storage = {
        path = "/vm/v-xpbx1/v-xpbx1.qcow2";  # Path to existing image
        type = "qcow2";  # Image format
        device = "disk";
      };
    }
    {
      name = "v-xwifi1";
      vcpu = "2";
      memory = "4";
      hostNic = "bridge21";
      mac = "52:54:00:8d:2e:ee";
      autostart = true;
      storage = {
        path = "/vm/v-xwifi1/v-xwifi1.qcow2";  # Path to existing image
        type = "qcow2";  # Image format
        device = "disk";
      };
    }
  ];

  # Function to generate VM XML content
  makeVmXml = vm: ''
    <domain type='kvm'>
      <name>${vm.name}</name>
      <memory unit='GiB'>${vm.memory}</memory>
      <vcpu>${vm.vcpu}</vcpu>
      <os>
        <type arch='x86_64' machine='pc-q35-8.1'>hvm</type>
        <boot dev='hd'/>
        <boot dev='cdrom'/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <vmport state='off'/>
      </features>
      <cpu mode='host-model'/>
      <clock offset='utc'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='no'/>
      </clock>
      <devices>
        <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2'/>
          <source file='${vm.storage.path}'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <disk type='file' device='cdrom'>
          <target dev='cdrom' bus='sata'/>
          <readonly/>
        </disk>
        <interface type='bridge'>
          <source bridge='${vm.hostNic}'/>
          <mac address='${vm.mac}'/>
          <model type='virtio'/>
        </interface>
        <graphics type='vnc' port='-1' autoport='yes' listen='127.0.0.1'>
          <listen type='address' address='127.0.0.1'/>
        </graphics>
        <console type='pty'/>
        <channel type='unix'>
          <target type='virtio' name='org.qemu.guest_agent.0'/>
        </channel>
        <input type='tablet' bus='usb'/>
        <input type='keyboard' bus='usb'/>
        <video>
          <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1'/>
        </video>
      </devices>
    </domain>
  '';

  # Create a service for each VM config
  mkVmConfigService = vm:
    let
      xmlFile = pkgs.writeText "${vm.name}-domain.xml" (makeVmXml vm);
    in {
      name = "libvirt-vm-${vm.name}";
      value = {
        description = "Create libvirt config for ${vm.name}";
        wantedBy = [ "multi-user.target" ];
        after = [ "libvirtd.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p /etc/libvirt/qemu && ${pkgs.coreutils}/bin/cp -f ${xmlFile} /etc/libvirt/qemu/${vm.name}.xml'";
        };
      };
    };

  # Generate all VM services
  vmServices = builtins.listToAttrs (map mkVmConfigService vmSpecs);

in
{
  systemd.services = vmServices;
}