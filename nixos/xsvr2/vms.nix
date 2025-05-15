{ pkgs, lib, ... }:

let
  vmSpecs = [
    {
      name = "v-k8s-xsvr2";
      vcpu = "4";
      memory = "16";
      hostNic = " bridge22";
      mac = "52:54:00:8d:2e:fe";
      autostart = true;
      firmware = "efi";
      storage = {
        path = "/zfs/vm/v-k8s-xsvr2/v-k8s-xsvr2.qcow2";
      };
      extraDrives = [
        {
          path = "/dev/disk/by-id/ata-CT1000MX500SSD1_2323E6E0F5AD";
          device = "disk";
          bus = "sata";
          target = "sdb";
          driverType = "raw";
        }
      ];
    }
  ];

  makeDriveXml = drive: ''
    <disk type='block' device='${drive.device or "disk"}'>
      <driver name='qemu' type='${drive.driverType or "raw"}'/>
      <source dev='${drive.path}'/>
      <target dev='${drive.target or "sdb"}' bus='${drive.bus or "sata"}'/>
      <address type='drive'/>
    </disk>
  '';

  # Function to generate VM XML content
  makeVmXml = vm: ''
    <domain type='kvm'>
      <name>${vm.name}</name>
      <memory unit='GiB'>${vm.memory}</memory>
      <vcpu>${vm.vcpu}</vcpu>
      <os>
        <type arch='x86_64' machine='pc-q35-8.1'>hvm</type>
        ${if vm.firmware == "efi" then ''
          <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
          <nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.fd'>/var/lib/libvirt/qemu/nvram/${vm.name}_VARS.fd</nvram>
        '' else ""}
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
          <target dev='hdc' bus='sata'/>
          <readonly/>
        </disk>
        ${lib.concatStringsSep "\n" (
          map makeDriveXml (
            if vm ? extraDrives && vm.extraDrives != null then vm.extraDrives else []
          )
        )}
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
        requires = [ "libvirtd.service" ];
        after = [ "libvirtd.service" ];
        path = [ pkgs.libvirt ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "create-vm-${vm.name}" ''
            set -eu
            mkdir -p /etc/libvirt/qemu
            cp -f ${xmlFile} /etc/libvirt/qemu/${vm.name}.xml
            virsh define /etc/libvirt/qemu/${vm.name}.xml || true
            ${lib.optionalString vm.autostart "virsh autostart ${vm.name} || true"}
          '';
        };
      };
    };

  # Add path watching service for each VM
  mkVmWatcher = vm: {
    name = "watch-vm-${vm.name}";
    value = {
      path = {
        pathConfig.PathChanged = "/etc/libvirt/qemu/${vm.name}.xml";
        wantedBy = [ "multi-user.target" ];
      };
      service = {
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "update-vm-${vm.name}" ''
            set -eu
            autostart="disable"  # Initialize with default value
            # Check if VM exists and get autostart status
            if virsh dominfo "${vm.name}" >/dev/null 2>&1; then
              autostart=$(virsh dominfo "${vm.name}" | grep "Autostart:" | awk '{print $2}') || echo "disable"
              # Try to undefine if not running
              if ! virsh domstate "${vm.name}" | grep -q "running"; then
                ${if vm.firmware == "efi" then
                  "virsh undefine \"${vm.name}\" --nvram || true"
                else
                  "virsh undefine \"${vm.name}\" || true"
                }
              fi
            fi
            # Define the VM
            virsh define "/etc/libvirt/qemu/${vm.name}.xml" || true
            # Restore autostart if it was enabled
            if [ "$autostart" = "yes" ]; then
              virsh autostart "${vm.name}" || true
            fi
          '';
        };
        path = [ pkgs.libvirt pkgs.gawk ];
        after = [ "libvirtd.service" ];
      };
    };
  };

  # Generate all VM services and watchers
  vmServices = builtins.listToAttrs (map mkVmConfigService vmSpecs);
  vmWatchers = builtins.listToAttrs (map mkVmWatcher vmSpecs);
  
  # Merge all services into one attribute set
  allServices = vmServices // lib.mapAttrs (name: cfg: cfg.service) vmWatchers;

in
{
  systemd.services = allServices;
  systemd.paths = lib.mapAttrs (name: cfg: cfg.path) vmWatchers;
}
