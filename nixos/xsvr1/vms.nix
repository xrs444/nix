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
          <os>
            <type arch='x86_64' machine='pc-q35-8.1'>hvm</type>
            <boot dev='hd'/>
          </os>
          <features>
            <acpi/>
            <apic/>
          </features>
          <cpu mode='host-passthrough'/>
          <devices>
            <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
            <disk type='file' device='disk'>
              <driver name='qemu' type='qcow2'/>
              <source file='${conf.storage.path}'/>
              <target dev='vda' bus='virtio'/>
            </disk>
            <interface type='bridge'>
              <source bridge='${conf.hostNic}'/>
              <mac address='${conf.mac}'/>
              <model type='virtio'/>
            </interface>
            <console type='pty'>
              <target type='serial' port='0'/>
            </console>
          </devices>
        </domain>
      '') guests)}
    '';
  };
}