# Summary: Install kanidm-unixd-clients on Bazzite hosts
# This playbook ensures kanidm CLI tools are installed and available for all users
{pkgs, ...}: {
  playbook = [
    {
      name = "Install kanidm-unixd-clients";
      hosts = "all";
      become = true;
      gather_facts = true;

      tasks = [
        {
          name = "Check if kanidm is already installed";
          command = "which kanidm";
          register = "kanidm_check";
          failed_when = false;
          changed_when = false;
        }
        {
          name = "Install kanidm-unixd-clients using rpm-ostree";
          command = "rpm-ostree install kanidm-unixd-clients";
          register = "kanidm_install";
          failed_when = false;
          changed_when = "kanidm_install.rc == 0";
          when = "kanidm_check.rc != 0";
        }
        {
          name = "Verify kanidm installation";
          command = "kanidm --version";
          when = "kanidm_check.rc == 0";
          register = "kanidm_version";
          failed_when = false;
        }
        {
          name = "Display kanidm version";
          debug.msg = "kanidm is installed: {{ kanidm_version.stdout }}";
          when = "kanidm_check.rc == 0 and kanidm_version.rc == 0";
        }
        {
          name = "Reboot required notice";
          debug.msg = "⚠️  A reboot is required to complete the kanidm-unixd-clients installation. Run: systemctl reboot";
          when = "kanidm_install.changed and kanidm_check.rc != 0";
        }
      ];
    }
  ];
}
