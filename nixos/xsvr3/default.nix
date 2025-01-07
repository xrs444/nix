{ lib, ... }: {
  imports = 
    map (
      path: builtins.import path 
    ) 
    (lib.filter (n: lib.strings.hasSuffix ".nix" n) (lib.filesystem.listFilesRecursive ./));
}
