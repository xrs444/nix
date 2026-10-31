# Nixible configuration for xdt1-t-game (Bazzite host)
{pkgs, ...}: let
  common = import ../common/default.nix {inherit pkgs;};
in {
  # Inherit common collections and extend with host-specific ones if needed
  collections = common.collections // {};

  # Inventory configuration for this host
  inventory = {
    all = {
      hosts = {
        xdt1-t-game = {
          # Bazzite self-reports "xdt1-t-game" as its hostname, but that only resolves via
          # mDNS (xdt1-t-game.local) — the static DNS/DHCP reservation for this physical
          # box (shared with its NixOS boot) is xdt1-t.lan. Use that so ansible can connect.
          ansible_host = "xdt1-t.lan";
          ansible_connection = "ssh";
          ansible_user = "ansible";
        };
      };
      vars = common.vars;
    };
  };

  # Host-specific playbook
  playbook = [
    {
      name = "Basic configuration for xdt1-t-game";
      hosts = "xdt1-t-game";
      gather_facts = true;
      become = true;

      tasks = [
        {
          name = "Verify connectivity";
          ping = {};
        }
        {
          name = "Display host information";
          debug.msg = "Connected to {{ inventory_hostname }} ({{ ansible_distribution }} {{ ansible_distribution_version }})";
        }
        {
          name = "Ensure just is installed";
          package = {
            name = "just";
            state = "present";
          };
        }
        {
          name = "Install kanidm-unixd-clients";
          package = {
            name = "kanidm-unixd-clients";
            state = "present";
          };
        }
        {
          name = "Create thomas-local user";
          user = {
            name = "thomas-local";
            state = "present";
            shell = "/bin/bash";
            create_home = true;
            comment = "thomas-local user";
            groups = "wheel";
            append = true;
          };
        }
        {
          name = "Create .ssh directory for thomas-local";
          file = {
            path = "/home/thomas-local/.ssh";
            state = "directory";
            owner = "thomas-local";
            group = "thomas-local";
            mode = "0700";
          };
        }
        {
          name = "Deploy SSH public keys for thomas-local";
          "ansible.posix.authorized_key" = {
            user = "thomas-local";
            key = "{{ item }}";
            state = "present";
          };
          loop = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAqv4pyiFGSFn91VWEQ4o2buVrGxlFUsFakiNcMJysK thomas-local@xrs444.net"
          ];
        }
        # xprn2 network printer (HP Color LaserJet Pro MFP M281cdw).
        # Driverless IPP Everywhere queue — Bazzite's base image ships CUPS,
        # so no PPD/hplip package layering is needed. Same pattern as
        # xdt2-g/xdt3-r.
        {
          name = "Ensure CUPS is running";
          systemd = {
            name = "cups";
            enabled = true;
            state = "started";
          };
        }
        {
          name = "Check whether the xprn2 print queue exists";
          command = "lpstat -p xprn2";
          register = "xprn2_queue";
          failed_when = false;
          changed_when = false;
        }
        {
          name = "Add xprn2 print queue";
          # Device URI must be the raw IP, not xprn2.lan: the printer's
          # embedded cupsd validates the HTTP Host header and rejects
          # anything but its own IP with a generic 400 (confirmed
          # 2026-08-30 -- see nix/modules/services/printing/default.nix
          # for the full diagnosis).
          command = "lpadmin -p xprn2 -E -v ipp://172.18.5.1/ipp/print -m everywhere -D 'HP Color LaserJet Pro MFP M281cdw'";
          when = "xprn2_queue.rc != 0";
          # Printer may still be genuinely powered off; don't let that fail
          # the whole play, just retry next run.
          failed_when = false;
        }
      ];
    }
  ];
}
