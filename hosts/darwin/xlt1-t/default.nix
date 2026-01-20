{
  hostname,
  pkgs,
  ...
}:
{
  imports = [
    ../default.nix
  ];

  # Host-specific configuration for xlt1-t (MacBook)
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.primaryUser = "xrs444";

  # macOS-specific settings
  system.defaults = {
    menuExtraClock.Show24Hour = true;
    dock = {
      autohide = true;
      orientation = "left";
      tilesize = 36;
      largesize = 48;
      scroll-to-open = true;
      persistent-apps = [
        "/Applications/Visual Studio Code.app"
        "/Applications/Firefox.app"
        "/Applications/Ghostty.app"
      ];
    };
    controlcenter = {
      BatteryShowPercentage = true;
    };
    finder = {
      AppleShowAllExtensions = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      FXPreferredViewStyle = "clmv";
      AppleShowAllFiles = true;
      FXRemoveOldTrashItems = true;
      ShowExternalHardDrivesOnDesktop = false;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = false;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      AppleInterfaceStyle = "Dark";
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
    };
  };

  # Remote builders configuration
  nix.buildMachines = [
    {
      hostName = "xsvr1.lan";
      sshUser = "builder";
      sshKey = "/Users/xrs444/.ssh/builder_key";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    }
  ];
  nix.distributedBuilds = true;

  # Manual PAM configuration for Touch ID (if needed)
  environment.etc."pam.d/sudo_local".text = ''
    # Written by nix-darwin for Touch ID support
    auth       sufficient     pam_tid.so
  '';

  programs.zsh.enable = true;
  programs.zsh.shellInit = ''
    # Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    # End Nix
  '';

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    # Nix
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end
    # End Nix

    # Add user's nix profile to PATH for Home Manager packages
    fish_add_path --prepend --global $HOME/.nix-profile/bin

    # Set environment variables for xrs444
    set -gx EDITOR micro
    set -gx BROWSER firefox
    set -gx SOPS_AGE_KEY_FILE $HOME/.config/sops/age/keys.txt
    set -gx KUBECONFIG $HOME/k8s/kubeconfig
    set -gx TALOSCONFIG $HOME/k8s/talosconfig
  '';
  programs.fish.shellAliases = {
    nix-sh = "fish $HOME/.local/bin/nix-sh.fish";
  };
  programs.fish.interactiveShellInit = ''
    # Initialize atuin for fish (only if not already initialized)
    if command -v atuin > /dev/null; and not set -q ATUIN_SESSION
      atuin init fish | source
    end
  '';

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  # Start atuin daemon as a LaunchAgent for the user
  launchd.user.agents.atuin-daemon = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.atuin}/bin/atuin"
        "daemon"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardErrorPath = "/tmp/atuin-daemon.stderr";
      StandardOutPath = "/tmp/atuin-daemon.stdout";
    };
  };
}
