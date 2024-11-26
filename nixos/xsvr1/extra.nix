{ lib, pkgs, ... }:
{
  imports = [ 
    ../common/services/nfs/xsvr1.nix 
    ../common/services/zfs
    ../common/services/openssh.nix    
    ];

}

