# Skip test phases for Python packages that fail in the Nix sandbox.
#
# MUST come before nix-vscode-extensions in the overlay list so that
# prev.python3 seen by that overlay already has the patched django.
#
# WHY checkPhase = ":" (not doCheck = false):
# overrideAttrs (_: { doCheck = false; }) changes the doCheck env var but NOT
# the `phases` string already baked into the derivation with "checkPhase" in
# it (phases is computed once from the original doCheck=true). nixpkgs setup.sh
# iterates that baked phases list and runs `eval "${!checkPhase}"`. Setting
# `checkPhase = ":"` replaces the phase function with a shell no-op: setup.sh
# still calls it, but it exits 0 immediately. Hash changes, no tests run.
#
# WHY only override django (not debugpy):
# Python package sets use lib.makeExtensible with self-references. Packages NOT
# listed in packageOverrides are re-evaluated in the new fixed-point where
# self.django = pyfinal.django. Overriding debugpy = pyprev.debugpy.overrideAttrs
# would start from pyprev.debugpy whose nativeBuildInputs already holds the
# original django — hardcoding the old reference back in.
#
# Re-export python3 and python3Packages so nix-vscode-extensions (overlay #2)
# sees the patched packages in its `prev` — without this, python3 in prev
# resolves to the frozen base-nixpkgs alias and the override has no effect.
final: prev: {
  python313 = prev.python313.override {
    packageOverrides = pyfinal: pyprev: {
      django = pyprev.django.overrideAttrs (_: { checkPhase = ":"; });
      # Mirror the pkgs.nix python3 override: some packages (e.g. remarshal) use
      # python313/python313Packages directly rather than the python3 alias, so
      # this must be patched here as well as in pkgs.nix's python3 override.
      rich = pyprev.rich.overrideAttrs (_: { doCheck = false; doInstallCheck = false; });
      # pipx 1.8.0 tests assert old spacing (no space before @) but Python
      # 3.13's packaging library normalizes to PEP 508 spacing (space before @).
      # Runtime behavior is correct; tests are stale upstream.
      # Tests run in installCheckPhase (via pytest-check-hook), not checkPhase,
      # so doInstallCheck = false is required in addition to checkPhase = ":".
      pipx = pyprev.pipx.overrideAttrs (_: { checkPhase = ":"; doInstallCheck = false; });
    };
  };
  python3 = final.python313;
  python3Packages = final.lib.recurseIntoAttrs final.python313.pkgs;
}
