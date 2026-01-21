# Summary: Install just command runner on Bazzite hosts
# This playbook ensures just is installed and available for all users
{pkgs, ...}: {
  playbook = [
    {
      name = "Install just command runner";
      hosts = "all";
      become = true;
      gather_facts = true;

      tasks = [
        {
          name = "Install just using rpm-ostree";
          command = "rpm-ostree install just";
          register = "just_install";
          failed_when = false;
          changed_when = "just_install.rc == 0";
        }
        {
          name = "Check if just is already installed";
          command = "which just";
          register = "just_check";
          failed_when = false;
          changed_when = false;
        }
        {
          name = "Verify just installation";
          command = "just --version";
          when = "just_check.rc == 0";
          register = "just_version";
        }
        {
          name = "Display just version";
          debug.msg = "just is installed: {{ just_version.stdout }}";
          when = "just_check.rc == 0";
        }
        {
          name = "Reboot required notice";
          debug.msg = "⚠️  A reboot is required to complete the just installation. Run: systemctl reboot";
          when = "just_install.changed and just_check.rc != 0";
        }
      ];
    }
  ];
}
