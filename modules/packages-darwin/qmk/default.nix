{ pkgs, ... }:    
{    
    # Add QMK CLI tools and related utilities as packages
    environment.systemPackages = with pkgs; [
      qmk
      dfu-util
      avrdude
      hidapi
      python3
      # Add any other keyboard flashing tools you need
    ];
}