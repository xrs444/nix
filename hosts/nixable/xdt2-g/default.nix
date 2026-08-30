# Nixible configuration for xdt2-g (Bazzite host)
{pkgs, ...}: let
  common = import ../common/default.nix {inherit pkgs;};
in {
  # Inherit common collections and extend with host-specific ones if needed
  collections = common.collections // {};

  # Inventory configuration for this host
  inventory = {
    all = {
      hosts = {
        xdt2-g = {
          ansible_host = "xdt2-g";
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
      name = "Basic configuration for xdt2-g";
      hosts = "xdt2-g";
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
        # Push-to-talk voice-to-text (voxtype.io) via Linuxbrew — xdt2-g is
        # Bazzite (rpm-ostree, immutable base), not this flake's NixOS/HM
        # tree, so it gets voxtype from Homebrew instead of nixpkgs, same
        # as xlt1-t (see modules/packages-darwin/brew-packages.nix). Uses
        # the peteonrails/voxtype tap's Formula, NOT the Cask — the Cask
        # downloads a macOS-only .dmg and will not work on Linux. brew
        # itself refuses to run as root, so these steps run as
        # thomas-local via become_user, unlike the rest of this play.
        # NOT YET VERIFIED end-to-end — xdt2-g was offline (gaming PC, not
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
        {
          name = "Tap peteonrails/voxtype";
          become = true;
          become_user = "thomas-local";
          shell = "/home/linuxbrew/.linuxbrew/bin/brew tap peteonrails/voxtype";
          args.creates = "/home/linuxbrew/.linuxbrew/Library/Taps/peteonrails/homebrew-voxtype";
        }
        {
          name = "Install voxtype via Homebrew";
          become = true;
          become_user = "thomas-local";
          shell = "/home/linuxbrew/.linuxbrew/bin/brew install peteonrails/voxtype/voxtype";
          args.creates = "/home/linuxbrew/.linuxbrew/bin/voxtype";
        }
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
          command = "lpadmin -p xprn2 -E -v ipp://xprn2.lan/ipp/print -m everywhere -D 'HP Color LaserJet Pro MFP M281cdw'";
          when = "xprn2_queue.rc != 0";
          # xprn2 is often asleep and won't answer the IPP query lpadmin -m
          # everywhere needs; don't let that fail the whole play, just retry
          # next run (confirmed 2026-08-30 on xlt2-s: same failure mode).
          failed_when = false;
        }
      ];
    }
  ];
}
