# Summary: RTC wake alarm service for xcomm1 — wakes the machine 10 minutes before the nightly auto-upgrade timer (04:30) and re-arms after each upgrade run.
{ pkgs, lib, ... }:
{
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
