{ lib, ... }:
{
  # Mask obsolete options to prevent build errors from upstream hardware module
  boot.binfmtMiscRegistrations = lib.mkForce null;
  boot.bootMount = lib.mkForce null;
  boot.loader.grub.bootDevice = lib.mkForce null;

  # Mask deprecated systemd Watchdog options
  systemd.settings.Manager.WatchdogDevice = lib.mkForce null;
  systemd.settings.Manager.KExecWatchdogSec = lib.mkForce null;
  systemd.settings.Manager.RebootWatchdogSec = lib.mkForce null;
  systemd.settings.Manager.RuntimeWatchdogSec = lib.mkForce null;

  # Mask missing user service startLimit options
  systemd.user.services.dbus.startLimitBurst = lib.mkForce null;
  systemd.user.services.dbus.startLimitIntervalSec = lib.mkForce null;
  systemd.user.services.nixos-activation.startLimitBurst = lib.mkForce null;
  systemd.user.services.nixos-activation.startLimitIntervalSec = lib.mkForce null;
  systemd.user.services.systemd-tmpfiles-setup.startLimitBurst = lib.mkForce null;
  systemd.user.services.systemd-tmpfiles-setup.startLimitIntervalSec = lib.mkForce null;
  systemd.user.services.user-session-thomas-local.startLimitBurst = lib.mkForce null;
  systemd.user.services.user-session-thomas-local.startLimitIntervalSec = lib.mkForce null;
  systemd.user.targets.nixos-fake-graphical-session.startLimitBurst = lib.mkForce null;
  systemd.user.targets.nixos-fake-graphical-session.startLimitIntervalSec = lib.mkForce null;
  systemd.user.timers.systemd-tmpfiles-clean.startLimitBurst = lib.mkForce null;
  systemd.user.timers.systemd-tmpfiles-clean.startLimitIntervalSec = lib.mkForce null;
  systemd.user.sockets.dbus.startLimitBurst = lib.mkForce null;
  systemd.user.sockets.dbus.startLimitIntervalSec = lib.mkForce null;
}
