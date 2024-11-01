_: {
  programs = {
    tmate.enable = true;

    tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = true;
      sensibleOnTop = true;
      # This should either be screen-256color or tmux-256color where it exists
      terminal = "tmux-256color";
    };
  };
}
