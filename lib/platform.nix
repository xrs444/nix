# Summary: Platform selection utility for NixOS, chooses platform-specific defaults for configuration.
{ lib }:

{ platform, default }:
  if platform != null then platform else lib.mkDefault default