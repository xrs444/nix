# Nixible configuration for xdash1 (DietPi host — HA dashboard kiosk)
{pkgs, ...}: let
  common = import ../common/default.nix {inherit pkgs;};
in {
  # Inherit common collections and extend with host-specific ones if needed
  collections = common.collections // {};

  # Inventory configuration for this host
  inventory = {
    all = {
      hosts = {
        xdash1 = {
          ansible_host = "xdash1";
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
      name = "Basic configuration for xdash1";
      hosts = "xdash1";
      # DietPi has no python3 out of the box, so fact-gathering (and every other
      # Ansible module, which all shell out to a python interpreter on the target)
      # fails until it's installed via the interpreter-free "raw" module below.
      gather_facts = false;
      become = true;

      tasks = [
        {
          name = "Bootstrap python3 (required for all other Ansible modules)";
          raw = "which python3 || (apt-get update && apt-get install -y python3)";
          changed_when = false;
        }
        {
          name = "Gather facts";
          setup = {};
        }
        {
          name = "Verify connectivity";
          ping = {};
        }
        {
          name = "Display host information";
          debug.msg = "Connected to {{ inventory_hostname }} ({{ ansible_distribution }} {{ ansible_distribution_version }})";
        }
        {
          # DietPi is Debian-based, so the ansible package module resolves this via apt.
          name = "Install prometheus-node-exporter";
          package = {
            name = "prometheus-node-exporter";
            state = "present";
          };
        }
        {
          name = "Ensure node exporter is enabled and running";
          systemd = {
            name = "prometheus-node-exporter";
            enabled = true;
            state = "started";
          };
        }
        {
          # DietPi/Debian has no "wheel" group by default (unlike the Fedora-based
          # Bazzite hosts) — use "sudo" for the Debian admin group instead.
          name = "Create thomas-local user";
          user = {
            name = "thomas-local";
            state = "present";
            shell = "/bin/bash";
            create_home = true;
            comment = "thomas-local user";
            groups = "sudo";
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
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPKuEzwE067tav1hJ44etyUMBlgPIeNqRn4E1+zPt7dK"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAqv4pyiFGSFn91VWEQ4o2buVrGxlFUsFakiNcMJysK thomas-local@xrs444.net"
          ];
        }

        # --- Kiosk display (HA dashboard, portrait 4K TV) ---
        # DietPi's 64MB default CMA (contiguous memory) reservation is too small for a
        # double-buffered 4K framebuffer (~63MB needed) and makes Xorg fail ScreenInit
        # at 3840x2160 while 1080p works fine — see .wolf/buglog.json bug-442.
        # cma=256M fixes it; video=...,rotate=90 sets native portrait 4K at the kernel/DRM
        # level so no xrandr call is needed once X starts.
        {
          name = "Set kernel cmdline: 4K portrait rotation + enough CMA to actually drive it";
          "ansible.builtin.lineinfile" = {
            path = "/boot/dietpiEnv.txt";
            regexp = "^extraargs=";
            line = "extraargs=fsck.repair=yes net.ifnames=0 video=HDMI-A-1:3840x2160,rotate=90 cma=256M";
          };
          notify = "Reboot xdash1";
        }
        {
          name = "Set chromium kiosk window size to portrait 4K (2160x3840)";
          "ansible.builtin.lineinfile" = {
            path = "/boot/dietpi.txt";
            regexp = "^{{ item.key }}=";
            line = "{{ item.key }}={{ item.value }}";
          };
          loop = [
            {
              key = "SOFTWARE_CHROMIUM_RES_X";
              value = "2160";
            }
            {
              key = "SOFTWARE_CHROMIUM_RES_Y";
              value = "3840";
            }
          ];
          loop_control.label = "{{ item.key }}";
        }
        {
          # Deployed declaratively so a reflashed SD card (or DietPi's own installer
          # regenerating this file) can't silently reintroduce the dead xrandr line
          # (sat after an unreachable `exec`) that caused bug-440/442's investigation.
          name = "Deploy chromium-autostart.sh (kiosk launcher)";
          "ansible.builtin.copy" = {
            dest = "/var/lib/dietpi/dietpi-software/installed/chromium-autostart.sh";
            owner = "root";
            group = "root";
            mode = "0755";
            content = ''
              #!/bin/dash
              # Autostart script for kiosk mode, based on @AYapejian: https://github.com/MichaIng/DietPi/issues/1737#issue-318697621

              # Resolution to use for kiosk mode, should ideally match current system resolution
              RES_X=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_RES_X=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)
              RES_Y=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_RES_Y=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)

              # Command line switches: https://peter.sh/experiments/chromium-command-line-switches/
              # - Review and add custom flags in: /etc/chromium.d
              CHROMIUM_OPTS="--kiosk --window-size=''${RES_X:-1280},''${RES_Y:-720} --window-position=0,0"

              # If you want tablet mode, uncomment the next line.
              #CHROMIUM_OPTS="$CHROMIUM_OPTS --force-tablet-mode --tablet-ui"

              # Home page
              URL=$(sed -n '/^[[:blank:]]*SOFTWARE_CHROMIUM_AUTOSTART_URL=/{s/^[^=]*=//p;q}' /boot/dietpi.txt)

              # Use "startx" as non-root user to get required permissions via systemd-logind
              STARTX='xinit'
              [ "$USER" = 'root' ] || STARTX='startx'

              # Rotation is handled kernel-side (video=...,rotate=90 in dietpiEnv.txt), so X
              # already gets a correctly-oriented portrait framebuffer — no xrandr call needed.
              exec "$STARTX" /usr/bin/chromium $CHROMIUM_OPTS "''${URL:-https://dietpi.com/}"
            '';
          };
          notify = "Reboot xdash1";
        }
      ];

      handlers = [
        {
          name = "Reboot xdash1";
          "ansible.builtin.reboot" = {
            reboot_timeout = 120;
          };
        }
      ];
    }
  ];
}
