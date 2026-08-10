# Summary: Home Manager configuration for user 'samantha', sets state version and user environment.
{
  lib,
  pkgs,
  desktop ? null,
  ...
}:
{
  home.stateVersion = "25.05";

  imports = lib.optional (builtins.isString desktop) ../../common/desktop;

  # System-wide default font: Dyslexie, served from the read-only fonts share
  # on xsvr1 (nix/hosts/nixos/xlt2-s/fonts.nix mounts it and sets the
  # fontconfig sans-serif alias). Set here in GNOME's own dconf key so it
  # applies to the desktop shell/UI, not just fontconfig-aware apps.
  dconf.settings."org/gnome/desktop/interface" = lib.mkIf pkgs.stdenv.isLinux {
    font-name = "Dyslexie 11";
    document-font-name = "Dyslexie 11";
  };

  # Desktop wallpaper, served from the read-only distribute share on xsvr1
  # (nix/hosts/nixos/xlt2-s/shares.nix mounts it) so image files don't have
  # to live in git. Automount triggers on first access, same as the fonts
  # share.
  dconf.settings."org/gnome/desktop/background" = lib.mkIf pkgs.stdenv.isLinux {
    picture-uri = "file:///mnt/xsvr1/distribute/wallpaper/ponyta.png";
    picture-uri-dark = "file:///mnt/xsvr1/distribute/wallpaper/ponyta.png";
    picture-options = "zoom";
  };

  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.vja
    pkgs.vikunja-desktop
    # Google Drive sync for Samantha's own account (separate Insync license
    # from xrs444's — see homemanager/users/xrs444/default.nix). xlt2-s runs
    # GNOME, so insync-nautilus adds Insync's right-click integration into
    # Files/Nautilus. First run needs an interactive `insync start` login
    # (OAuth) — not something Nix can provision declaratively.
    pkgs.insync
    pkgs.insync-nautilus
  ];

  # vja (Vikunja CLI) server config — non-secret. The API token is decrypted
  # by sops-nix (modules/users/samantha.nix) to its default /run/secrets/
  # location, then symlinked into ~/.config/vja/token.json below.
  home.file.".config/vja/config.rc".text = lib.mkIf pkgs.stdenv.isLinux ''
    [application]
    frontend_url=https://vikunja.xrs444.net/
    api_url=https://vikunja.xrs444.net/api/v1
  '';

  # Symlink the sops-managed token into vja's expected location.
  # Deliberately not a sops `path` override — see
  # homemanager/users/xrs444/default.nix for why that races with this same-
  # directory config.rc write and can silently break other home-manager-
  # managed dotfiles.
  home.activation.linkVjaToken = lib.mkIf pkgs.stdenv.isLinux (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      $DRY_RUN_CMD ln -sfn /run/secrets/vikunja-api-token-samantha "$HOME/.config/vja/token.json"
    ''
  );
}
