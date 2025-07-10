{
  inputs,
  outputs,
  stateVersion,
  platform ? null,
  ...
}:
let
  helpers = import ./helpers.nix { inherit inputs outputs stateVersion platform; };
in
{
  inherit (helpers)
    mkDarwin
    mkHome
    mkNixos
    forAllSystems
    ;
}