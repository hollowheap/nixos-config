(function()
  local function to_argb(c, alpha)
    local hex = type(c) == "string" and c:match("(%x%x%x%x%x%x)") or "000000"
    return tonumber((alpha or "ff") .. hex, 16)
  end
  local ok, m = pcall(require, "noctalia")
  if ok and type(m) == "table" and type(m.colors) == "table" then
    if type(m.apply_theme) == "function" then m.apply_theme() end
    return {
      active_border = m.colors.primary,
      inactive_border = m.colors.surface,
      active_shadow = "rgba(00000055)",
      inactive_shadow = "rgba(00000026)",
      bg_color = to_argb(m.colors.surface, "ff"),
      label_color = to_argb(m.colors.on_surface, "ff"),
      label_background = to_argb(m.colors.surface, "cc"),
    }
  end
  return {
    active_border = "rgba(ffffffff)",
    inactive_border = "rgba(ffffff88)",
    active_shadow = "rgba(00000055)",
    inactive_shadow = "rgba(00000026)",
    bg_color = 0xff000000,
    label_color = 0xffffffff,
    label_background = 0xcc000000,
  }
end)()