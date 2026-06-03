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

      # Wrapper script that copies source to a writable temp dir before running,
      # because the tool clones repos into its own directory
      cat > $out/bin/nb-dt-import <<'WRAPPER'
      #!/usr/bin/env bash
      WORK_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/netbox-devicetype-import"
      mkdir -p "$WORK_DIR"
      # Copy source files if not already present
      if [ ! -f "$WORK_DIR/nb-dt-import.py" ]; then
        cp -r @src@/* "$WORK_DIR/"
        chmod -R u+w "$WORK_DIR"
      fi
      cd "$WORK_DIR"
      exec @python@ "$WORK_DIR/nb-dt-import.py" "$@"
      WRAPPER
      substituteInPlace $out/bin/nb-dt-import \
        --replace-quiet "@src@" "$out/lib/netbox-devicetype-import" \
        --replace-quiet "@python@" "${pkgs.python3}/bin/python3"
      chmod +x $out/bin/nb-dt-import

      # Also wrap with PYTHONPATH for the dependencies
      wrapProgram $out/bin/nb-dt-import \
        --prefix PYTHONPATH : "$PYTHONPATH" \
        --prefix PYTHONPATH : "$out/lib/netbox-devicetype-import"
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
