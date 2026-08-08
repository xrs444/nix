{
  lib,
  pkgs,
  hostname ? null,
  ...
}:

let
  # xcog1 is a headless LLM server (see nix/docs/xcog1-llm-deployment-plan.md)
  # — none of the workstation-oriented submodules or package pile below are
  # needed there, and several (brew-packages.nix's ~30 GUI casks, apple
  # Container's postActivation GitHub-release fetch, netbox/qmk tooling)
  # actively worked against getting its first switch to build cleanly.
  isServer = hostname == "xcog1";
in
{
  imports = [
    ../packages-common/kanidm
  ]
  ++ lib.optionals (!isServer) [
    ./apple-container/default.nix
    ./brew-packages.nix
    ./netbox-devicetype-import/default.nix
    ./qmk/default.nix
  ]
  ++ [
    ./tmux/default.nix
  ];

  # Darwin-specific packages (Nix packages). xcog1 gets a minimal core+
  # marginal+diagnostics set (mirrors homemanager/users/xrs444/default.nix's
  # isServer split) instead of the full workstation list.
  environment.systemPackages =
    with pkgs;
    if isServer then
      [
        age
        git
        wget
        home-manager
        sops
      ]
    else
      [
        age
        git
        wget
        fish
        lame
        x264
        hugo
        lua
        nodejs
        openjdk
        ruby
        ansible

        # Kubernetes & Cloud Native
        cilium-cli
        cmctl
        fluxcd
        hubble
        kubectl
        kubeseal
        kustomize
        talosctl

        # System utilities
        arping
        home-manager
        nmap
        sops
        sshpass
        tfswitch
        tree
        yamllint
        yq

        # Compression & archives
        _7zz
        brotli
        lz4
        lzo
        p7zip
        wimlib
        xz
        zstd

        # Utilities
        wireshark
        openscad
        powershell
        # vscode is managed by home-manager with pkgs.unstable (see homemanager/common/apps/vscode)

        # Other utilities
        pipx
        virtualenv

        # Active Directory management (Samba AD / Windows AD)
        openrsat
      ];
}
