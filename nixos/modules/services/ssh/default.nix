
{
  isInstall,
  isLaptop,
  lib,
  pkgs,
  ...
}:
{
  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = lib.mkDefault "false";
      };
    };
#    sshguard = {
#      enable = true;
#      whitelist = [
#        "192.168.2.0/24"
#        "62.31.16.154"
#        "80.209.186.64/28"
      ];
    };
  };
}