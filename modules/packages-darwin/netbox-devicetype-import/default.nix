{ pkgs, ... }:

let
  netbox-devicetype-import = pkgs.python3Packages.buildPythonApplication {
    pname = "netbox-devicetype-import";
    version = "unstable";
    format = "other";

    src = pkgs.fetchFromGitHub {
      owner = "netbox-community";
      repo = "Device-Type-Library-Import";
      # To update: nix-prefetch-url --unpack https://github.com/netbox-community/Device-Type-Library-Import/archive/<new-commit>.tar.gz
      rev = "237f76a64b32c4d6043e48137d86ea546f5fc577";
      hash = "sha256-lusR6A+C9+3cVAZFJc53w+qVHdGIXmE3o003b71oZGU=";
    };

    propagatedBuildInputs = with pkgs.python3Packages; [
      gitpython
      pynetbox
      python-dotenv
      pyyaml
    ];

    installPhase = ''
      mkdir -p $out/bin $out/lib/netbox-devicetype-import
      cp -r . $out/lib/netbox-devicetype-import/
      makeWrapper ${pkgs.python3}/bin/python3 $out/bin/nb-dt-import \
        --prefix PYTHONPATH : "$PYTHONPATH" \
        --prefix PYTHONPATH : "$out/lib/netbox-devicetype-import" \
        --add-flags "$out/lib/netbox-devicetype-import/nb-dt-import.py"
    '';

    nativeBuildInputs = [ pkgs.makeWrapper ];

    doCheck = false;

    meta = with pkgs.lib; {
      description = "Import device types from the NetBox Device Type Library";
      homepage = "https://github.com/netbox-community/Device-Type-Library-Import";
      license = licenses.asl20;
    };
  };
in
{
  environment.systemPackages = [ netbox-devicetype-import ];
}
