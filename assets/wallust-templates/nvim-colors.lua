-- wallust template (minijinja) -> rendered to ~/.config/nvf/lua/wallust.lua
--
-- Ported from the noctalia nvim-colors.lua template. Keeps the same module
-- shape: M.setup() feeds a base16 palette into base16-colorscheme, and a
-- SIGUSR1 handler hot-reloads the palette + lualine theme when wallust fires
-- its post-run hook (`pkill -SIGUSR1 nvim`), mirroring noctalia's behaviour.
--
-- Noctalia M3 roles are mapped onto wallust ansi slots. base16-colorscheme
-- expects '#RRGGBB' values, so the '#'-prefixed `{{colorN}}` form is used.
--
-- PIN: base00-base07 are pinned to a clean monochromatic neutral ramp (#000000 to #ffffff)
-- so dark themes maintain readable neutrals regardless of dynamic palette extraction.
-- base08-base0F use high-contrast bright ANSI variants for syntax highlighting.
local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    -- Background tones (monochromatic neutral ramp)
    base00 = '#000000',       -- Default Background (pure black)
    base01 = '#1a1a1a',       -- Lighter Background
    base02 = '#2e2e2e',       -- Selection Background (dark charcoal)
    base03 = '#555555',       -- Comments, Invisibles, Line numbers
    -- Foreground tones
    base04 = '#888888',       -- Dark Foreground (status bars, hints)
    base05 = '#e0e0e0',       -- Default Foreground (soft off-white)
    base06 = '#eeeeee',       -- Light Foreground
    base07 = '#ffffff',       -- Lightest Foreground (pure white)
    -- Accent colors (bright ANSI variants for dark theme contrast)
    base08 = '{{color9}}',    -- Bright Red (Variables, XML Tags, Errors)
    base09 = '{{color9}}',    -- Bright Red (Integers, Constants)
    base0A = '{{color11}}',   -- Bright Yellow (Classes, Search Background)
    base0B = '{{color10}}',   -- Bright Green (Strings, Diff Inserted)
    base0C = '{{color14}}',   -- Bright Cyan (Regex, Escape Chars)
    base0D = '{{color12}}',   -- Bright Blue (Functions, Methods)
    base0E = '{{color13}}',   -- Bright Magenta (Keywords, Storage)
    base0F = '{{color13}}',    -- Bright Magenta (Deprecated, Embedded Tags)
  })
end

if not _G._wallust_signal then
  _G._wallust_signal = vim.uv.new_signal()
  _G._wallust_signal:start('sigusr1',
    vim.schedule_wrap(function()
      package.loaded['wallust'] = nil
      require('wallust').setup()
      if _G.update_lualine_theme then
        _G.update_lualine_theme()
      end
    end)
  )
end

return M
