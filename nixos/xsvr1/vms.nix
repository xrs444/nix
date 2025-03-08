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

  guests = lib.listToAttrs (map (vm: lib.nameValuePair vm.name {
    inherit (vm) memory mac storage vcpu autostart hostNic;
    }) vmSpecs);

in

{
  virtualisation.libvirtd = {
    onBoot = "start";
    onShutdown = "shutdown";
    extraConfig = ''
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: conf: ''
        <domain type='kvm'>
          <name>${name}</name>
          <memory unit='GiB'>${conf.memory}</memory>
          <vcpu>${conf.vcpu}</vcpu>
            <type arch='x86_64'>hvm</type>
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
              <source file='${conf.storage.path}'/>
              <target dev='vda' bus='virtio'/>
            </disk>
            <disk type='file' device='cdrom'>
              <target dev='hda' bus='ide'/>
              <readonly/>
            </disk>
            <interface type='bridge'>
              <source bridge='${conf.hostNic}'/>
              <mac address='${conf.mac}'/>
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
      '') guests)}
    '';
  };
}