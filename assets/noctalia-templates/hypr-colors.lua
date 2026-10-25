return {
  active_border = {
    colors = {
      "rgba({{ colors.primary.default.hex_stripped }}ee)",
      "rgba({{ colors.secondary.default.hex_stripped }}ee)",
      "rgba({{ colors.tertiary.default.hex_stripped }}ee)",
      "rgba({{ colors.primary_container.default.hex_stripped }}ee)",
      "rgba({{ colors.secondary_container.default.hex_stripped }}ee)"
    },
    angle = 45
  },
  inactive_border = "rgba({{ colors.surface_variant.default.hex_stripped }}aa)",
  active_shadow = "rgba({{ colors.shadow.default.hex_stripped }}ee)",
  inactive_shadow = "rgba({{ colors.shadow.default.hex_stripped }}aa)"
}
