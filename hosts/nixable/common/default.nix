# Summary: Common nixible configuration for Bazzite hosts, shared collections and settings
{...}: {
  # Common Ansible collections used across all nixable hosts
  # Add frequently used collections here with their versions and hashes
  collections = {
    # Provides the authorized_key module used by every host's SSH key deployment task
    "ansible-posix" = {
      version = "2.2.2";
      hash = "sha256-AKWMXYBMmtyZw8PcG58iRvS7X3M3lBRA4JVvDjHDuCs=";
    };
  };

  # Common configuration that can be shared across all nixable hosts
  # Individual host configs can override these settings

  # Common variables that can be used in playbooks
  vars = {
    # Ansible user for automation
    ansible_user = "ansible";

    # Private key deployed by: just extract-thomas-local-key
    ansible_private_key_file = "~/.ssh/thomas-local_key";

    # Become settings for privilege escalation
    ansible_become = true;
    ansible_become_method = "sudo";
  };
}
