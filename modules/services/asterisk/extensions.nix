# Summary: Asterisk dialplan (extensions.conf) for xpbx1 internal extensions
{ lib, hostname, hostRoles ? [ ], ... }:
let
  isXpbx1 = lib.elem "asterisk" hostRoles && hostname == "xpbx1";
in
{
  config = lib.mkIf isXpbx1 {
    services.asterisk.confFiles."extensions.conf" = ''
      ; Dialplan configuration for xpbx1

      [general]
      static = yes
      writeprotect = no

      [internal]
      ; Direct extension dialing
      exten => 801,1,NoOp(Calling Home Assistant)
      same => n,Dial(PJSIP/801,30)
      same => n,Hangup()

      exten => 802,1,NoOp(Ring Group - All Extensions)
      same => n,Dial(PJSIP/801&PJSIP/810&PJSIP/811&PJSIP/812&PJSIP/813&PJSIP/814&PJSIP/815&PJSIP/816&PJSIP/817&PJSIP/818,30)
      same => n,Hangup()

      exten => 810,1,NoOp(Calling RF Cabinet)
      same => n,GotoIfTime(07:00-18:59,*,*,*?allowed)
      same => n,Playback(closed)
      same => n,Hangup()
      same => n(allowed),Dial(PJSIP/810,30)
      same => n,Hangup()

      exten => 811,1,NoOp(Calling Greyson's Room)
      same => n,GotoIfTime(07:00-18:59,*,*,*?allowed)
      same => n,Playback(closed)
      same => n,Hangup()
      same => n(allowed),Dial(PJSIP/811,30)
      same => n,Hangup()

      exten => 812,1,NoOp(Calling Rowan's Room)
      same => n,GotoIfTime(07:00-18:59,*,*,*?allowed)
      same => n,Playback(closed)
      same => n,Hangup()
      same => n(allowed),Dial(PJSIP/812,30)
      same => n,Hangup()

      exten => 813,1,NoOp(Calling Garage)
      same => n,Dial(PJSIP/813,30)
      same => n,Hangup()

      exten => 814,1,NoOp(Calling Rack)
      same => n,Dial(PJSIP/814,30)
      same => n,Hangup()

      exten => 815,1,NoOp(Calling Thomas' Desk)
      same => n,Dial(PJSIP/815,30)
      same => n,Hangup()

      exten => 816,1,NoOp(Calling Samantha's Desk)
      same => n,Dial(PJSIP/816,30)
      same => n,Hangup()

      exten => 817,1,NoOp(Calling xstarfish)
      same => n,Dial(PJSIP/817,30)
      same => n,Hangup()

      exten => 818,1,NoOp(Calling Master Bedroom)
      same => n,Dial(PJSIP/818,30)
      same => n,Hangup()

      ; Pattern for invalid extensions
      exten => _X.,1,NoOp(Invalid extension: ''${EXTEN})
      same => n,Playback(invalid)
      same => n,Hangup()
    '';
  };
}
