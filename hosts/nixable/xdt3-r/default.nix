# Nixible configuration for xdt3-r (Bazzite host)
{pkgs, ...}: let
  common = import ../common/default.nix {inherit pkgs;};
in {
  # Inherit common collections and extend with host-specific ones if needed
  collections = common.collections // {};

  # Inventory configuration for this host
  inventory = {
    all = {
      hosts = {
        xdt3-r = {
          ansible_host = "xdt3-r";
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
      name = "Basic configuration for xdt3-r";
      hosts = "xdt3-r";
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
          authorized_key = {
            user = "thomas-local";
            key = "{{ item }}";
            state = "present";
          };
          loop = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAqv4pyiFGSFn91VWEQ4o2buVrGxlFUsFakiNcMJysK thomas-local@xrs444.net"
          ];
        }
      ];
    }
  ];
}
