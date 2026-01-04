{ pkgs, ... }:
{
  programs.fish = {
    enable = pkgs.stdenv.isLinux;
    
    # Shell initialization for justfile awareness
    interactiveShellInit = ''
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
