# Skip test phases for Python packages that fail in the Nix sandbox.
# Must use python313.override (not python3Packages // {...}) because VSCode
# extensions reference python3.pkgs (the interpreter's internal fixed-point)
# via withPackages — a top-level alias override doesn't propagate there.
final: prev: {
  python313 = prev.python313.override {
    packageOverrides = pyfinal: pyprev: {
      debugpy = pyprev.debugpy.overrideAttrs (_: { doCheck = false; });
      django = pyprev.django.overrideAttrs (_: { doCheck = false; });
    };
  };
}
