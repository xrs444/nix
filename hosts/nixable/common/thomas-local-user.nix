# Summary: Deploy thomas-local user to Bazzite hosts
# This playbook creates the thomas-local user with sudo access and SSH keys
{pkgs, ...}: {
  playbook = [
    {
      name = "Setup thomas-local user";
      hosts = "all";
      become = true;
      gather_facts = true;

      tasks = [
        {
          name = "Create thomas-local user";
          user = {
            name = "thomas-local";
            state = "present";
            shell = "/bin/bash";
            create_home = true;
            comment = "thomas-local user";
            password = "$6$rounds=656000$YourSaltHere$YourHashHere"; # Placeholder - user should set password
          };
        }
        {
          name = "Add thomas-local user to wheel group for sudo access";
          user = {
            name = "thomas-local";
            groups = "wheel";
            append = true;
          };
        }
        {
          name = "Create .ssh directory for thomas-local user";
          file = {
            path = "/home/thomas-local/.ssh";
            state = "directory";
            owner = "thomas-local";
            group = "thomas-local";
            mode = "0700";
          };
        }
        {
          name = "Deploy SSH public keys for thomas-local user";
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
        {
          name = "Verify thomas-local user setup";
          debug.msg = "thomas-local user successfully configured on {{ inventory_hostname }}";
        }
      ];
    }
  ];
}
