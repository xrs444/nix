{
  config,
  hostname,
  lib,
  pkgs,
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
	          "valid users" = "whoever";
            "time machine" = true;
         };
      };
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
}

