{ lib, pkgs, ... }:
{
  imports = [ 
    ../common/services/nfs/xsvr1.nix 
    ../common/services/zfs-kernel
    ../common/services/openssh.nix    
    ];

}
