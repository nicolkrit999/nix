{ pkgs, ... }:
let
  # ----------------------------------------------------------------------------
  # 1. Custom Linemode Logic
  # (This MUST go into the global init.lua, Yazi's entry point)
  # ----------------------------------------------------------------------------
  customLinemode = ''
    function Linemode:custom_metadata()
        local size = self._file:size()
        local size_mb = size and string.format("%.2f MB", size / 1024 / 1024) or "-"

        -- Format Birth Time
        local btime = math.floor(self._file.cha.btime or 0)
        local btime_str = btime ~= 0 and os.date("%d.%m.%y", btime) or "unk"

        -- Format Modified Time
        local mtime = math.floor(self._file.cha.mtime or 0)
        local mtime_str = mtime ~= 0 and os.date("%d.%m.%y", mtime) or "unk"

        return string.format(" %s | mod: %s | cre: %s ", size_mb, mtime_str, btime_str)
    end
  '';
in
{
  # ----------------------------------------------------------------------------
  # WRITING THE FILES
  # ----------------------------------------------------------------------------

  # Global config must be named 'init.lua'
  xdg.configFile."yazi/init.lua".text = customLinemode;
}
