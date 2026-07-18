{ ... }:
{
  # Justfile for ripping bin/cue discs into the Romm library via redumper.
  # cd ~/rips && just list-drives / just rip <drive> "<game name>"
  home.file."rips/justfile".source = ./rip.justfile;
}
