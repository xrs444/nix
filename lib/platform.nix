{ lib }:

{ platform, default }:
  if platform != null then platform else lib.mkDefault default