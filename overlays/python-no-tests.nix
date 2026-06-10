# Skip test phases for Python packages that fail in the Nix sandbox.
#
# The overlay chain uses a shallow `//` merge: setting python313 alone does NOT
# update python3 or python3Packages in `prev` for subsequent overlays — those
# still resolve to the frozen base-nixpkgs values. nix-vscode-extensions reads
# prev.python3Packages.debugpy (original drv) when wrapping ms-python.python,
# so the hash never changes no matter what we do to python313.
#
# Fix: explicitly re-export all three aliases from the overridden interpreter,
# so nix-vscode-extensions sees the new debugpy/django in its `prev`.
final: prev: {
  python313 = prev.python313.override {
    packageOverrides = pyfinal: pyprev: {
      debugpy = pyprev.debugpy.overrideAttrs (_: { doCheck = false; });
      django = pyprev.django.overrideAttrs (_: { doCheck = false; });
    };
  };
  python3 = final.python313;
  python3Packages = final.lib.recurseIntoAttrs final.python313.pkgs;
}
