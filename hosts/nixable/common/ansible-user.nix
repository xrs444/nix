# Summary: Ansible user setup configuration for Bazzite hosts
# This creates a dedicated ansible user with sudo privileges and SSH key authentication
{pkgs, ...}: {
  # Common playbook for setting up the ansible user on Bazzite hosts
  # This should be run once during initial host setup

  playbook = [
    {
      name = "Setup Ansible user";
      hosts = "all";
      become = true;
      gather_facts = true;

      tasks = [
        {
          name = "Create ansible user";
          user = {
            name = "ansible";
            state = "present";
            shell = "/bin/bash";
            create_home = true;
            comment = "Ansible automation user";
          };
        }
        {
          name = "Add ansible user to wheel group for sudo access";
          user = {
            name = "ansible";
            groups = "wheel";
            append = true;
          };
        }
        {
          name = "Allow ansible user passwordless sudo";
          lineinfile = {
            path = "/etc/sudoers.d/ansible";
            line = "ansible ALL=(ALL) NOPASSWD: ALL";
            create = true;
            mode = "0440";
            validate = "visudo -cf %s";
          };
        }
        {
          name = "Create .ssh directory for ansible user";
          file = {
            path = "/home/ansible/.ssh";
            state = "directory";
            owner = "ansible";
            group = "ansible";
            mode = "0700";
          };
        }
        {
          name = "Deploy SSH public key for ansible user";
          authorized_key = {
            user = "ansible";
            key = "{{ lookup('file', ansible_ssh_public_key_path) }}";
            state = "present";
          };
          when = "ansible_ssh_public_key_path is defined";
        }
        {
          name = "Verify ansible user setup";
          debug.msg = "Ansible user successfully configured on {{ inventory_hostname }}";
        }
      ];
    }
  ];
}
