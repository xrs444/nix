# Skip test phases for Python packages that fail in the Nix sandbox.
#
# MUST come before nix-vscode-extensions in the overlay list so that
# prev.python3 seen by that overlay already has the patched debugpy.
#
# Use `.override { doCheck = false; }` (not overrideAttrs) so that
# buildPythonPackage is re-run with doCheck=false from the start.
# overrideAttrs only patches the final mkDerivation attrs — it leaves
# nativeCheckInputs already merged into nativeBuildInputs, so django
# (a debugpy nativeCheckInput) is still built and its tests fail.
# With .override, nativeCheckInputs are not added to nativeBuildInputs
# at all, so django is never pulled in and the hash actually changes.
#
# Re-export python3 and python3Packages so nix-vscode-extensions (overlay #2)
# sees the patched packages in its `prev` — without this, python3 in prev
# resolves to the frozen base-nixpkgs alias and the override has no effect.
final: prev: {
  python313 = prev.python313.override {
    packageOverrides = pyfinal: pyprev: {
      debugpy = pyprev.debugpy.override { doCheck = false; };
    };
  };
  python3 = final.python313;
  python3Packages = final.lib.recurseIntoAttrs final.python313.pkgs;
}
