{ pkgs, lib, ... }:

let
  vmSpecs = [
    {
      name = "v-k8s-xsvr2";
      vcpu = "6"; # Increased from 4 - was CPU starved at 288%, max out Atom cores (leave 2 for host)
      memory = "80"; # MASSIVELY increased from 16 GiB - xsvr2 has 128GB and only uses 21GB total!
      nicType = "bridge";
      hostNic = "bridge22"; # Use the VLAN interface for direct mode
      mac = "52:54:00:8d:2e:fe";
      autostart = true;
      firmware = "efi";
      storage = {
        path = "/vm/v-k8s-xsvr2/v-k8s-xsvr2.qcow2";
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
      withVnic = true; # Set to true to enable the virtual NIC
      pciDevices = [ ];
    }
  ];

  makeDriveXml = drive: ''
    <disk type='block' device='${drive.device or "disk"}'>
      <driver name='qemu' type='${drive.driverType or "raw"}'/>
      <source dev='${drive.path}'/>
      <target dev='${drive.target or "sdb"}' bus='${drive.bus or "sata"}'/>
      ${
        # virtio disks are PCI devices -- a 'drive'-type address (meant for
        # IDE/SATA controller addressing) is invalid on them and libvirt
        # rejects the whole XML. Let libvirt auto-assign a PCI slot instead.
        if (drive.bus or "sata") == "virtio" then "" else "<address type='drive'/>"
      }
    </disk>
  '';

  makePciHostdevXml = pci: ''
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <source>
        <address domain='${pci.domain}' bus='${pci.bus}' slot='${pci.slot}' function='${pci.function}'/>
      </source>
    </hostdev>
  '';

  # Function to generate VM XML content
  makeVmXml = vm: ''
    <domain type='kvm'>
      <name>${vm.name}</name>
      <memory unit='GiB'>${vm.memory}</memory>
      <vcpu>${vm.vcpu}</vcpu>
      <os>
        <type arch='x86_64' machine='pc-q35-8.1'>hvm</type>
        ${
          if vm.firmware == "efi" then
            ''
              <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/edk2-x86_64-code.fd</loader>
            ''
          else
            ""
        }
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
          map makeDriveXml (if vm ? extraDrives && vm.extraDrives != null then vm.extraDrives else [ ])
        )}
        ${lib.concatStringsSep "\n" (
          map makePciHostdevXml (if vm ? pciDevices && vm.pciDevices != null then vm.pciDevices else [ ])
        )}
        ${
          if vm.withVnic or true then
            if vm.nicType == "macvtap" then
              ''
                <interface type='macvtap'>
                  <source dev='${vm.hostNic}' mode='${vm.macvtapMode or "bridge"}'/>
                  <mac address='${vm.mac}'/>
                  <model type='virtio'/>
                </interface>
              ''
            else if vm.nicType == "direct" then
              ''
                <interface type='direct' trustGuestRxFilters="yes">
                  <source dev='${vm.hostNic}' mode='${vm.macvtapMode or "bridge"}'/>
                  <mac address='${vm.mac}'/>
                  <model type='virtio'/>
                </interface>
              ''
            else
              ''
                <interface type='bridge'>
                  <source bridge='${vm.hostNic}'/>
                  <mac address='${vm.mac}'/>
                  <model type='virtio'/>
                </interface>
              ''
          else
            ""
        }
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
  mkVmConfigService =
    vm:
    let
      xmlFile = pkgs.writeText "${vm.name}-domain.xml" (makeVmXml vm);
    in
    {
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

            # Preserve the already-persisted domain UUID (if any). The generated
            # XML has no <uuid>, and defining a same-name domain without one can
            # conflict with libvirt's existing record ("already exists with uuid
            # X") -- silently, if the caller swallows the error. Pin it explicitly
            # so redefines always update in place instead of racing that conflict.
            if existing_uuid=$(virsh domuuid "${vm.name}" 2>/dev/null); then
              sed -i "s#<name>${vm.name}</name>#<name>${vm.name}</name>\n  <uuid>$existing_uuid</uuid>#" /etc/libvirt/qemu/${vm.name}.xml
            fi

            virsh define /etc/libvirt/qemu/${vm.name}.xml
            ${lib.optionalString vm.autostart "virsh autostart ${vm.name}"}
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
            existing_uuid=""
            # Check if VM exists and get autostart status
            if virsh dominfo "${vm.name}" >/dev/null 2>&1; then
              autostart=$(virsh dominfo "${vm.name}" | grep "Autostart:" | awk '{print $2}') || echo "disable"
              # Capture the UUID before undefining so the redefine below can pin
              # it -- otherwise a same-name domain with no <uuid> in its XML can
              # conflict with libvirt's existing record on define.
              existing_uuid=$(virsh domuuid "${vm.name}" 2>/dev/null || echo "")
              # Try to undefine only when fully stopped
              state=$(virsh domstate "${vm.name}" 2>/dev/null || echo "undefined")
              if [ "$state" = "shut off" ] || [ "$state" = "undefined" ]; then
                ${
                  if vm.firmware == "efi" then
                    "virsh undefine \"${vm.name}\" --nvram || true"
                  else
                    "virsh undefine \"${vm.name}\" || true"
                }
              fi
            fi
            # Pin the previous UUID (if any) so this redefine updates the same
            # domain record instead of racing an "already exists" conflict.
            if [ -n "$existing_uuid" ]; then
              sed -i "s#<name>${vm.name}</name>#<name>${vm.name}</name>\n  <uuid>$existing_uuid</uuid>#" "/etc/libvirt/qemu/${vm.name}.xml"
            fi
            # Define the VM
            virsh define "/etc/libvirt/qemu/${vm.name}.xml"
            # Restore autostart if it was enabled
            if [ "$autostart" = "yes" ]; then
              virsh autostart "${vm.name}"
            fi
          '';
        };
        path = [
          pkgs.libvirt
          pkgs.gawk
        ];
        # First-boot race (bug-676): the sibling libvirt-vm-<name>.service
        # (mkVmConfigService) also virsh-defines this domain. Without this
        # ordering, both units' PathChanged/wantedBy triggers can fire
        # concurrently and race to define the same domain, one failing with
        # "already exists with uuid X".
        after = [
          "libvirtd.service"
          "libvirt-vm-${vm.name}.service"
        ];
        wants = [ "libvirt-vm-${vm.name}.service" ];
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
