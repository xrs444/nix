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
        # Don't open the firewall on for SSH on laptops; Tailscale will handle it.
#        openFirewall = !isLaptop;
        settings = {
          PasswordAuthentication = true;
          PermitRootLogin = "no";
        };
      };
#      sshguard = {
#        enable = true;
#        whitelist = [
#         "192.168.2.0/24"
#          "62.31.16.154"
#          "80.209.186.64/28"
#        ];
#      };
  };
}
