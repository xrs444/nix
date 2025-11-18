{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.pip
  ];
  shellHook = ''
    pip install --user qmk
    export PATH="$HOME/.local/bin:$PATH"
  '';
}
