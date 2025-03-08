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
  # Enable libvirtd
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf.enable = true;
      runAsRoot = true;
    };
    # Define the VMs
    extraConfig = ''
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: conf: ''
        <domain type='kvm'>
          <name>${name}</name>
          <memory unit='GiB'>${conf.memory}</memory>
          <vcpu>${conf.vcpu}</vcpu>
          <os>
            <type arch='x86_64'>hvm</type>
          </os>
          <devices>
            <disk type='file' device='disk'>
              <source file='${conf.storage.path}'/>
              <target dev='vda' bus='virtio'/>
            </disk>
            <interface type='bridge'>
              <source bridge='${conf.hostNic}'/>
              <mac address='${conf.mac}'/>
              <model type='virtio'/>
            </interface>
          </devices>
        </domain>
      '') guests)}
    '';
  };
}
