# Skip test phases for Python packages that fail in the Nix sandbox.
# debugpy has django in checkInputs; doCheck=false prevents django from being
# built at all, which avoids django's own sandbox-incompatible test suite.
_: prev: {
  python3Packages = prev.python3Packages // {
    debugpy = prev.python3Packages.debugpy.overrideAttrs (_: { doCheck = false; });
    django = prev.python3Packages.django.overrideAttrs (_: { doCheck = false; });
  };
}
