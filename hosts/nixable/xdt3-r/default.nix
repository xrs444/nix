# Nixible configuration for xdt3-r (Bazzite host)
{pkgs, ...}: let
  common = import ../common/default.nix {inherit pkgs;};
in {
  # Inherit common collections and extend with host-specific ones if needed
  collections = common.collections // {};

  # Bazzite ships Python 3.15 only, and ansible-core 2.21.x modules crash on it
  # (AttributeError: dataclasses has no attribute '_is_type'; ansible/ansible#87677).
  # 2.22 is the first release supporting 3.15 but nixpkgs still packages 2.21.5.
  # Drop this override once nixpkgs ships ansible-core >= 2.22.
  ansiblePackage = pkgs.python3Packages.ansible-core.overridePythonAttrs (old: rec {
    version = "2.22.0";
    src = pkgs.fetchPypi {
      pname = "ansible_core";
      inherit version;
      hash = "sha256-v1C0oM+pheMFhce6MBiX6nBQ0iTKSdKBbKsQ4zoWDhw=";
    };
    # nixpkgs patches target 2.21.x and may not apply to 2.22.
    patches = [];
  });

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
        # kanidm-unixd-clients removed 2026-11-24: not in Bazzite's Fedora 44/45 repos,
        # and xdt2-g/xdt3-r use local accounts (greyson/rowan) instead of Kanidm login.
        # Re-add once a package source exists.
        # Flatpaks added on top of the stock Bazzite set (system-wide, from Flathub).
        # `flatpak install` is a no-op when already present; changed_when keys off its
        # output so reruns report ok instead of changed.
        {
          name = "Install extra flatpaks";
          shell = "flatpak install --system --noninteractive flathub {{ item }}";
          register = "flatpak_install";
          changed_when = "'Installation complete' in flatpak_install.stdout";
          loop = [
            "com.google.Chrome"
            "com.mojang.Minecraft"
            "com.vysp3r.ProtonPlus"
            "com.github.Matoking.protontricks"
            "com.bitwarden.desktop"
          ];
        }
        # No screen lock / password prompt on wake (system-wide dconf defaults).
        # Uses the stock "local" dconf db, already in /etc/dconf/profile/user.
        {
          name = "Disable GNOME screen lock";
          copy = {
            dest = "/etc/dconf/db/local.d/00-no-screenlock";
            owner = "root";
            group = "root";
            mode = "0644";
            content = ''
              [org/gnome/desktop/screensaver]
              lock-enabled=false

              [org/gnome/desktop/session]
              idle-delay=uint32 0

              [org/gnome/desktop/lockdown]
              disable-lock-screen=true

              [org/gnome/settings-daemon/plugins/power]
              sleep-inactive-ac-type='suspend'
              sleep-inactive-ac-timeout=900
              sleep-inactive-battery-type='suspend'
              sleep-inactive-battery-timeout=900
            '';
          };
          register = "dconf_screenlock";
        }
        {
          name = "Rebuild dconf database";
          command = "dconf update";
          when = "dconf_screenlock.changed";
        }
        # Chrome homepage. The flatpak has host-etc access, so it reads policies from
        # /etc/opt/chrome/policies. "recommended" sets the default but leaves it
        # user-changeable (use .../managed to lock it instead).
        {
          name = "Create Chrome recommended-policy directory";
          file = {
            path = "/etc/opt/chrome/policies/recommended";
            state = "directory";
            mode = "0755";
          };
        }
        {
          name = "Set Chrome homepage";
          copy = {
            dest = "/etc/opt/chrome/policies/recommended/homepage.json";
            mode = "0644";
            content = ''
              {
                "HomepageLocation": "https://home.xrs444.net",
                "HomepageIsNewTabPage": false,
                "ShowHomeButton": true
              }
            '';
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
        # Local (non-Kanidm) account for the machine's day-to-day user, same model
        # as greyson on xdt2-g. No password set; the session autologins via GDM.
        {
          name = "Create rowan user";
          user = {
            name = "rowan";
            state = "present";
            shell = "/bin/bash";
            create_home = true;
            comment = "Rowan";
          };
        }
        {
          name = "Enable GDM automatic login as rowan";
          # lineinfile (builtin) rather than community.general.ini_file, which
          # isn't in this host's collection set.
          lineinfile = {
            path = "/etc/gdm/custom.conf";
            regexp = "^#?{{ item.key }}=";
            line = "{{ item.key }}={{ item.value }}";
            insertafter = "^\\[daemon\\]";
          };
          loop = [
            {
              key = "AutomaticLoginEnable";
              value = "True";
            }
            {
              key = "AutomaticLogin";
              value = "rowan";
            }
          ];
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
        # Push-to-talk voice-to-text (voxtype.io) via Linuxbrew — xdt3-r is
        # Bazzite (rpm-ostree, immutable base), not this flake's NixOS/HM
        # tree, so it gets voxtype from Homebrew instead of nixpkgs, same
        # as xlt1-t (see modules/packages-darwin/brew-packages.nix). Uses
        # the peteonrails/voxtype tap's Formula, NOT the Cask — the Cask
        # downloads a macOS-only .dmg and will not work on Linux. brew
        # itself refuses to run as root, so these steps run as
        # thomas-local via become_user, unlike the rest of this play.
        # NOT YET VERIFIED end-to-end — xdt3-r was offline (gaming PC, not
        # always powered on) when this was written, and voxtype has no
        # prebuilt bottle on this third-party tap, so `brew install` below
        # does a from-source cargo/cmake build (whisper.cpp + Rust
        # bindgen), which can be slow and has more ways to fail than a
        # bottled install. Re-run and check for errors once the host is up.
        {
          name = "Check for Linuxbrew installation";
          stat.path = "/home/linuxbrew/.linuxbrew/bin/brew";
          register = "linuxbrew_installed";
        }
        {
          name = "Create /home/linuxbrew directory owned by thomas-local";
          file = {
            path = "/home/linuxbrew";
            state = "directory";
            owner = "thomas-local";
            group = "thomas-local";
            mode = "0755";
          };
          when = "not linuxbrew_installed.stat.exists";
        }
        {
          name = "Install Homebrew (Linuxbrew) as thomas-local";
          become = true;
          become_user = "thomas-local";
          shell = ''NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'';
          when = "not linuxbrew_installed.stat.exists";
        }
        {
          name = "Add Homebrew shellenv to thomas-local's .bash_profile";
          become = true;
          become_user = "thomas-local";
          lineinfile = {
            path = "/home/thomas-local/.bash_profile";
            line = ''eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'';
            create = true;
          };
        }
        # voxtype tap/install removed 2026-11-26: peteonrails/voxtype 0.6.3 fails to
        # build (whisper-rs-sys bindgen size asserts, ~1h15m from-source on xdt2-g)
        # and has no bottle. Re-add the tap + `brew install peteonrails/voxtype/voxtype`
        # once the tap is patched.
        # xprn2 network printer (HP Color LaserJet Pro MFP M281cdw).
        # Driverless IPP Everywhere queue — Bazzite's base image ships CUPS,
        # so no PPD/hplip package layering is needed.
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
