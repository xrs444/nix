{ pkgs, ... }:
{
  programs.fish = {
    enable = pkgs.stdenv.isLinux;
    
    # Shell initialization for justfile awareness
    interactiveShellInit = ''
      # Force XDG_RUNTIME_DIR to match the actual current user, not whatever
      # was inherited from a parent session (e.g. `sudo su - xrs444` from
      # thomas-local leaves a stale /run/user/<other-uid> in the environment,
      # which breaks `just`'s runtime dir with a permission error).
      set -gx XDG_RUNTIME_DIR /run/user/(id -u)

      # Auto-load justfile completions
      if command -v just >/dev/null 2>&1
        # Generate completions for fish
        just --completions fish | source
        
        # Alias for quick access
        alias j='just'
        
        # Show available just recipes when entering a directory with a justfile
        function __auto_just_hint --on-variable PWD
          if test -f justfile -o -f Justfile -o -f .justfile
            echo "💡 Justfile detected! Run 'just' or 'just --list' to see available commands"
          end
        end
      end
    '';
  };
}
