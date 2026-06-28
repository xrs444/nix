# Summary: RTC wake alarm + WoWLAN (Wake-on-Wireless-LAN) services for xcomm1.
{ pkgs, ... }:
{
  # Arm the Intel WiFi NIC (wlp6s0) to wake on magic packet.
  # Two services: one at boot so the flag survives resume, one pre-sleep so it
  # is always re-armed just before the NIC enters low-power state.
  systemd.services.wowlan-enable = {
    description = "Enable Wake-on-Wireless-LAN on wlp6s0";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wowlan-enable" ''
        ${pkgs.iw}/bin/iw dev wlp6s0 set wowlan enable magic-pkt || true
      '';
    };
  };

  systemd.services.wowlan-pre-sleep = {
    description = "Re-arm Wake-on-Wireless-LAN before suspend";
    before = [
      "systemd-suspend.service"
      "systemd-hibernate.service"
      "systemd-hybrid-sleep.service"
      "systemd-suspend-then-hibernate.service"
    ];
    wantedBy = [
      "systemd-suspend.service"
      "systemd-hibernate.service"
      "systemd-hybrid-sleep.service"
      "systemd-suspend-then-hibernate.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "wowlan-pre-sleep" ''
        ${pkgs.iw}/bin/iw dev wlp6s0 set wowlan enable magic-pkt || true
      '';
    };
  };

  systemd.services.set-rtc-wake = {
    description = "Arm RTC wake alarm for nightly upgrade window";
    # Run at every boot so the alarm is always set, and again after each
    # upgrade so the next night's alarm is re-armed automatically.
    wantedBy = [
      "multi-user.target"
      "nixos-upgrade.service"
    ];
    after = [ "nixos-upgrade.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "set-rtc-wake" ''
        set -euo pipefail
        # Target: 04:20 America/Phoenix (10 min before nixos-upgrade.timer at 04:30).
        # If today's 04:20 is still in the future, use today; otherwise tomorrow.
        NOW=$(${pkgs.coreutils}/bin/date +%s)
        TODAY_ALARM=$(TZ="America/Phoenix" ${pkgs.coreutils}/bin/date -d "today 04:20" +%s)
        if [ "$TODAY_ALARM" -gt "$NOW" ]; then
          NEXT=$TODAY_ALARM
        else
          NEXT=$(TZ="America/Phoenix" ${pkgs.coreutils}/bin/date -d "tomorrow 04:20" +%s)
        fi
        echo "Arming RTC wake for $(${pkgs.coreutils}/bin/date -d @"$NEXT" --utc) UTC"
        echo 0 > /sys/class/rtc/rtc0/wakealarm
        echo "$NEXT" > /sys/class/rtc/rtc0/wakealarm
      '';
    };
  };
}
