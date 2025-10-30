{ pkgs, desktop, ... }:
{
  imports = [
    (./. + "/${desktop}")

  ];

  programs = {
    mpv.enable = true;
  };

  home.packages = with pkgs; [
    desktop-file-utils
  ];

  #fonts.fontconfig.enable = true;

  overlays = [
    (final: prev: {
      kanidm = unstablePkgs.kanidm_1_7;
      kanidmWithSecretProvisioning = unstablePkgs.kanidm_1_7.override {
        enableSecretProvisioning = true;
      };
    })
  ];
}
