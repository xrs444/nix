# Skip test phases for Python packages that fail in the Nix sandbox.
#
# MUST come before nix-vscode-extensions in the overlay list so that
# prev.python3 seen by that overlay already has the patched debugpy/django.
#
# Use .overrideAttrs (NOT .override) to skip tests. Python package functions
# have the form `{ lib, buildPythonPackage, ... }:` — the trailing `...`
# silently absorbs any extra args, so `.override { doCheck = false; }` is a
# complete no-op: the derivation hash is unchanged and tests still run.
# `.overrideAttrs (_: { doCheck = false; })` modifies the mkDerivation attrs
# directly, which changes the hash and causes the checkPhase to be skipped.
#
# Python package sets use lib.makeExtensible with self-references, so
# overriding django here propagates through the fixed-point: debugpy's
# nativeCheckInputs reference self.django, which resolves to our patched
# version, giving debugpy a new hash without manually filtering its inputs.
#
# Re-export python3 and python3Packages so nix-vscode-extensions (overlay #2)
# sees the patched packages in its `prev` — without this, python3 in prev
# resolves to the frozen base-nixpkgs alias and the override has no effect.
final: prev: {
  python313 = prev.python313.override {
    packageOverrides = pyfinal: pyprev: {
      # Only override django — do NOT also override debugpy here.
      # Python package sets use lib.makeExtensible: packages not listed in
      # packageOverrides are re-evaluated in the new fixed-point where
      # self.django = pyfinal.django (our new one). If we also override
      # debugpy = pyprev.debugpy.overrideAttrs(...), we start from pyprev.debugpy
      # whose nativeBuildInputs already contains the original django (old hash).
      # That hardcodes the old reference back in and the fix has no effect.
      django = pyprev.django.overrideAttrs (_: { doCheck = false; });
      # Mirror the pkgs.nix python3 override: some packages (e.g. remarshal) use
      # python313/python313Packages directly rather than the python3 alias, so
      # this must be patched here as well as in pkgs.nix's python3 override.
      rich = pyprev.rich.overrideAttrs (_: { doCheck = false; doInstallCheck = false; });
    };
  };
  python3 = final.python313;
  python3Packages = final.lib.recurseIntoAttrs final.python313.pkgs;
}
