# Summary: NixOS module for OpenSSH, enables SSH service and configures authentication and firewall settings.
{ ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

}
