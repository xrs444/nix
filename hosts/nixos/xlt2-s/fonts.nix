# Points fontconfig at the read-only fonts share mounted from xsvr1
# (see shares.nix) so custom fonts can be dropped in without ever being
# committed to git. The <dir> is scanned lazily — the automount in
# shares.nix triggers on first access, so fontconfig picks fonts up the
# first time anything asks for them (or after `fc-cache -f`).
{
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <dir>/mnt/xsvr1/distribute/fonts</dir>

      <!-- Dyslexie (dyslexiefont.com) as the default sans-serif — internal
           family name confirmed via the TTF name table, not the filename. -->
      <match target="pattern">
        <test name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>Dyslexie</string></edit>
      </match>
    </fontconfig>
  '';
}
