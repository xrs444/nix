{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:

let
  installOn = [
    "xsvr1"
  ];
in
lib.mkIf (lib.elem "${hostname}" installOn) {

   services.netatalk = {
    enable = true;
      settings = {
        time-machine = {
          path = "/zfs/systembackups/timemachine";
	          "valid users" = "Thomas Letherby";
            "time machine" = true;
         };
      };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
}

