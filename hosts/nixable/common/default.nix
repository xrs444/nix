# Summary: Common nixible configuration for Bazzite hosts, shared collections and settings
{pkgs, ...}: {
  # Common Ansible collections used across all Bazzite hosts
  # Add frequently used collections here with their versions and hashes
  collections = {
    # Example: Uncomment and add hash when needed
    # "community-general" = {
    #   version = "8.0.0";
    #   hash = "sha256-REPLACE_WITH_ACTUAL_HASH";
    # };
  };

  # Common configuration that can be shared across all nixable hosts
  # Individual host configs can override these settings

  # Common variables that can be used in playbooks
  vars = {
    # Ansible user for automation
    ansible_user = "ansible";

    # Become settings for privilege escalation
    ansible_become = true;
    ansible_become_method = "sudo";
  };
}
