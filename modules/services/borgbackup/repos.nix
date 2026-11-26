# Summary: BorgWarehouse repository names for every backed-up host, shared by the NixOS borg-client module and the nixable (Bazzite) playbooks.
#
# BorgWarehouse does NOT use the alias as the on-disk repo path: it generates an
# id (shown in the UI / `borg init` wizard as the part after `/./`). Create the
# repo in the UI with alias = hostname, then paste the generated name here.
# Until a host's name is set, only its SSH/passphrase plumbing is deployed —
# no backup job or timer is created.
{
  server = "borgwarehouse-ssh.xrs444.net";
  port = 2222;
  user = "borgwarehouse";

  repoNames = {
    "xlt2-s" = null;
    "xdt1-t" = null;
    "xdt2-g" = null;
    "xdt3-r" = null;
  };
}
