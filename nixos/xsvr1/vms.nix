{ pkgs, lib, ... }:
{

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


  # Convert list to attribute set
  guests = lib.listToAttrs (map (vm: lib.nameValuePair vm.name {
    inherit (vm) memory mac storage vcpu autostart;
    }) vmSpecs);

in

  {
    virtualisation.libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
    };

    # Create the VMs using the guest specifications
  virtualisation.libvirtd.guests = builtins.mapAttrs (name: conf:
    {
      networkInterfaces = [{
        type = "bridge";
        source.bridge = conf.hostNic;  # Use VM-specific bridge
        mac = conf.mac;
      }];
      vcpu = conf.vcpu;
      memory = conf.memory;
      autoStart = conf.autostart;
      storagePool = null;  # Don't use storage pool when using direct image path
      disks = [
        {
          inherit (conf.storage) device path type;
        }
      ];
    }
    ) guests;
  }

}