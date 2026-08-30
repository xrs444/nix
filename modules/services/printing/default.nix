# Summary: CUPS client and the xprn2 network print queue (HP Color LaserJet
# Pro MFP M281cdw) for workstation hosts.
{ hostname, lib, pkgs, ... }:
let
  printingHosts = [ "xdt1-t" "xlt2-s" ];
  # Must be the raw IP, not xprn2.lan: the printer's embedded cupsd validates
  # the HTTP Host header and rejects anything but its own IP with a generic
  # 400 "Bad Request - CUPS vX.Y.Z" (confirmed 2026-08-30 -- a byte-correct
  # IPP POST with Host: xprn2.lan:631 was rejected identically regardless of
  # resource path or operation; the identical request with Host: 172.18.5.1
  # got a valid 200 IPP response). This is the same Host-header validation
  # class of bug (CVE-2014-2856 mitigation) flagged in the k8s cups app
  # earlier, except here it's embedded firmware with no ServerAlias to fix.
  xprn2Uri = "ipp://172.18.5.1/ipp/print";
in
lib.mkIf (lib.elem hostname printingHosts) {
  services.printing.enable = true;

  # Not using hardware.printers.ensurePrinters: its generated
  # ensure-printers.service has no failure tolerance, and `lpadmin -m
  # everywhere` can fail for reasons outside our control (printer asleep,
  # or -- as confirmed 2026-08-30 -- rejected by the printer's Host-header
  # validation until the deviceUri was switched to its raw IP, see xprn2Uri
  # above). A hard-failed unit here is fatal to nixos-rebuild switch itself
  # (nixos-rebuild-ng raises on a failed unit), which would break every
  # future deploy to a printing host whenever the queue can't be created.
  # So this is a hand-rolled equivalent that always exits 0 and just retries
  # on the next switch/boot instead -- kept even after the Host-header fix,
  # since the printer being genuinely powered off is still a real case.
  systemd.services.ensure-xprn2 = {
    description = "Ensure xprn2 (HP M281cdw) CUPS queue exists";
    wantedBy = [ "multi-user.target" ];
    # network-online.target: without this, a boot-time run can race ahead of
    # the resolver and fail DNS ("Name or service not known") rather than
    # ever reaching the printer at all -- confirmed 2026-08-30 on xlt2-s.
    wants = [ "cups.service" "network-online.target" ];
    after = [ "cups.service" "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.cups}/bin/lpadmin -p xprn2 -E \
        -v ${xprn2Uri} -m everywhere \
        -D "HP Color LaserJet Pro MFP M281cdw" \
      && ${pkgs.cups}/bin/lpadmin -d xprn2 \
      || echo "xprn2 unreachable/not answering IPP -- will retry on next switch" >&2
    '';
  };
}
