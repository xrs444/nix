# Terminal Configuration Module

## Overview
This module provides terminal information database (terminfo) support for all NixOS hosts, with specific support for GhostTTY terminal emulator.

## Purpose
When SSH from a terminal emulator like GhostTTY to remote servers, the remote system needs terminfo definitions to properly handle terminal capabilities. Without these definitions, you may experience:
- Garbled output
- Broken cursor positioning
- Non-functional special keys
- Incorrect colors or formatting

## Configuration

### Provided Packages
- `ncurses`: Provides the terminfo database and tools

### Environment Variables
- `TERMINFO_DIRS`: Set to include system terminfo paths
- `TERM`: Falls back to `xterm-256color` if not set

### Terminfo Entries
The module creates terminfo entries for:
- `ghostty`: Symlinked to xterm-256color definition
- `xterm-ghostty`: Symlinked to xterm-256color definition

## How It Works

GhostTTY is compatible with xterm-256color, so we create symlinks pointing to the standard xterm-256color terminfo definition. This ensures that when you SSH from GhostTTY to a NixOS host, the remote system knows how to handle the terminal properly.

## Automatic Integration

This module is automatically imported by the `packages-common/default.nix` module through its directory auto-discovery mechanism. Any host that includes `packages-common` will have these terminal settings.

## Testing

To verify the configuration is working:

```bash
# Check if terminfo is available
infocmp xterm-256color

# Check if GhostTTY entry exists
ls -la /etc/terminfo/g/ghostty

# Test with SSH
ssh user@host "echo \$TERM && tput colors"
```

## Troubleshooting

If you experience terminal issues after SSHing:

1. Check `$TERM` value: `echo $TERM`
2. Verify terminfo exists: `infocmp $TERM`
3. Try explicitly setting TERM: `export TERM=xterm-256color`
4. Ensure ncurses is installed: `which infocmp`

## Related

- GhostTTY: https://ghostty.org/
- ncurses terminfo: https://invisible-island.net/ncurses/
- TERM environment variable: https://www.gnu.org/software/termutils/manual/termutils-2.0/html_chapter/tput_1.html
