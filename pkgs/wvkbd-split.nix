{ wvkbd, python3 }:
wvkbd.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ python3 ];
  postPatch = (old.postPatch or "") + ''
    python3 - <<'EOF'
with open("main.c", "r") as f:
    mc = f.read()
with open("main.c", "w") as f:
    f.write(mc.replace("static struct wl_compositor *compositor;", "struct wl_compositor *compositor;", 1))

with open("keyboard.c", "r") as f:
    kc = f.read()

old_draw = """    while (next_key->type != Last) {
        if ((next_key->type == Pad) || (next_key->type == EndRow)) {
            next_key++;
            continue;
        }
        if ((next_key->type == Mod && kb->mods & next_key->code) ||
            (next_key->type == Compose && kb->compose)) {
            kbd_draw_key(kb, next_key, Press);
        } else {
            kbd_draw_key(kb, next_key, None);
        }
        next_key++;
    }"""

new_draw = """    extern struct wl_compositor *compositor;
    struct wl_region *input_region = compositor ? wl_compositor_create_region(compositor) : NULL;
    while (next_key->type != Last) {
        if ((next_key->type == Pad) || (next_key->type == EndRow)) {
            next_key++;
            continue;
        }
        if ((next_key->type == Mod && kb->mods & next_key->code) ||
            (next_key->type == Compose && kb->compose)) {
            kbd_draw_key(kb, next_key, Press);
        } else {
            kbd_draw_key(kb, next_key, None);
        }
        if (input_region) {
            wl_region_add(input_region, next_key->x, next_key->y, next_key->w, next_key->h);
        }
        next_key++;
    }
    if (input_region && kb->surf && kb->surf->surf) {
        wl_surface_set_input_region(kb->surf->surf, input_region);
        wl_region_destroy(input_region);
    }"""

assert old_draw in kc, "old_draw not found in keyboard.c"
with open("keyboard.c", "w") as f:
    f.write(kc.replace(old_draw, new_draw, 1))

with open("layout.mobintl.h", "r") as f:
    content = f.read()

split_landscape = """static struct key keys_landscape[] = {
  {"Esc", "Esc", 1.0, Code, KEY_ESC, .scheme = 1},
  {"1", "!", 1.0, Code, KEY_1},
  {"2", "@", 1.0, Code, KEY_2},
  {"3", "#", 1.0, Code, KEY_3},
  {"4", "$", 1.0, Code, KEY_4},
  {"5", "%", 1.0, Code, KEY_5},
  {"", "", 3.0, Pad},
  {"6", "^", 1.0, Code, KEY_6},
  {"7", "&", 1.0, Code, KEY_7},
  {"8", "*", 1.0, Code, KEY_8},
  {"9", "(", 1.0, Code, KEY_9, &layouts[ComposeBracket]},
  {"0", ")", 1.0, Code, KEY_0, &layouts[ComposeBracket]},
  {"⌫", "⌫", 1.0, Code, KEY_BACKSPACE, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"Tab", "Tab", 1.0, Code, KEY_TAB, .scheme = 1},
  {"q", "Q", 1.0, Code, KEY_Q, &layouts[Emoji]},
  {"w", "W", 1.0, Code, KEY_W, &layouts[ComposeW]},
  {"e", "E", 1.0, Code, KEY_E, &layouts[ComposeE]},
  {"r", "R", 1.0, Code, KEY_R, &layouts[ComposeR]},
  {"t", "T", 1.0, Code, KEY_T, &layouts[ComposeT]},
  {"", "", 3.0, Pad},
  {"y", "Y", 1.0, Code, KEY_Y, &layouts[ComposeY]},
  {"u", "U", 1.0, Code, KEY_U, &layouts[ComposeU]},
  {"i", "I", 1.0, Code, KEY_I, &layouts[ComposeI]},
  {"o", "O", 1.0, Code, KEY_O, &layouts[ComposeO]},
  {"p", "P", 1.0, Code, KEY_P, &layouts[ComposeP]},
  {"-", "_", 1.0, Code, KEY_MINUS, &layouts[ComposeBracket]},
  {"", "", 0.0, EndRow},

  {"Ctr", "Ctr", 1.0, Mod, Ctrl, .scheme = 1},
  {"a", "A", 1.0, Code, KEY_A, &layouts[ComposeA]},
  {"s", "S", 1.0, Code, KEY_S, &layouts[ComposeS]},
  {"d", "D", 1.0, Code, KEY_D, &layouts[ComposeD]},
  {"f", "F", 1.0, Code, KEY_F, &layouts[ComposeF]},
  {"g", "G", 1.0, Code, KEY_G, &layouts[ComposeG]},
  {"", "", 3.0, Pad},
  {"h", "H", 1.0, Code, KEY_H, &layouts[ComposeH]},
  {"j", "J", 1.0, Code, KEY_J, &layouts[ComposeJ]},
  {"k", "K", 1.0, Code, KEY_K, &layouts[ComposeK]},
  {"l", "L", 1.0, Code, KEY_L, &layouts[ComposeL]},
  {"'", "\\"", 1.0, Code, KEY_APOSTROPHE, &layouts[ComposeBracket]},
  {"Enter", "Enter", 1.0, Code, KEY_ENTER, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"⇧", "⇫", 1.0, Mod, Shift, .scheme = 1},
  {"z", "Z", 1.0, Code, KEY_Z, &layouts[ComposeZ]},
  {"x", "X", 1.0, Code, KEY_X, &layouts[ComposeX]},
  {"c", "C", 1.0, Code, KEY_C, &layouts[ComposeC]},
  {"v", "V", 1.0, Code, KEY_V, &layouts[ComposeV]},
  {"b", "B", 1.0, Code, KEY_B, &layouts[ComposeB]},
  {"", "", 3.0, Pad},
  {"n", "N", 1.0, Code, KEY_N, &layouts[ComposeN]},
  {"m", "M", 1.0, Code, KEY_M, &layouts[ComposeM]},
  {",", "<", 1.0, Code, KEY_COMMA, &layouts[ComposeMath]},
  {".", ">", 1.0, Code, KEY_DOT, &layouts[ComposePunctuation]},
  {"/", "?", 1.0, Code, KEY_SLASH},
  {"⇧", "⇫", 1.0, Mod, Shift, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"⌨͕", "⌨͔", 1.0, NextLayer, .scheme = 1},
  {"Sup", "Sup", 1.0, Mod, Super, .scheme = 1},
  {"Alt", "Alt", 1.0, Mod, Alt, .scheme = 1},
  {"Cmp", "Cmp", 1.0, Compose, .scheme = 1},
  {"", "Tab", 2.0, Code, KEY_SPACE},
  {"", "", 3.0, Pad},
  {"", "Tab", 2.0, Code, KEY_SPACE},
  {"←", "←", 1.0, Code, KEY_LEFT, .scheme = 1},
  {"↓", "↓", 1.0, Code, KEY_DOWN, .scheme = 1},
  {"↑", "↑", 1.0, Code, KEY_UP, .scheme = 1},
  {"→", "→", 1.0, Code, KEY_RIGHT, .scheme = 1},

  /* end of layout */
  {"", "", 0.0, Last},
};

static struct key keys_landscape_special[] = {
  {"Esc", "Esc", 1.0, Code, KEY_ESC, .scheme = 1},
  {"1", "!", 1.0, Code, KEY_1},
  {"2", "@", 1.0, Code, KEY_2},
  {"3", "#", 1.0, Code, KEY_3},
  {"4", "$", 1.0, Code, KEY_4},
  {"5", "%", 1.0, Code, KEY_5},
  {"", "", 3.0, Pad},
  {"6", "^", 1.0, Code, KEY_6},
  {"7", "&", 1.0, Code, KEY_7},
  {"8", "*", 1.0, Code, KEY_8},
  {"9", "(", 1.0, Code, KEY_9, &layouts[ComposeBracket]},
  {"0", ")", 1.0, Code, KEY_0, &layouts[ComposeBracket]},
  {"Del", "Del", 1.0, Code, KEY_DELETE, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"Tab", "Tab", 1.0, Code, KEY_TAB, .scheme = 1},
  {"`", "~", 1.0, Code, KEY_GRAVE},
  {"'", "\\"", 1.0, Code, KEY_APOSTROPHE},
  {"-", "_", 1.0, Code, KEY_MINUS},
  {"=", "+", 1.0, Code, KEY_EQUAL},
  {"🙂", "🙂", 1.0, Layout, 0, &layouts[Emoji]},
  {"", "", 3.0, Pad},
  {"[", "{", 1.0, Code, KEY_LEFTBRACE},
  {"]", "}", 1.0, Code, KEY_RIGHTBRACE},
  {"\\\\", "|", 1.0, Code, KEY_BACKSLASH},
  {";", ":", 1.0, Code, KEY_SEMICOLON},
  {"/", ">", 1.0, Code, KEY_SLASH},
  {"⌫", "⌫", 1.0, Code, KEY_BACKSPACE, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"Ctr", "Ctr", 1.0, Mod, Ctrl, .scheme = 1},
  {"⇤", "⇤", 1.0, Code, KEY_HOME, .scheme = 1},
  {"⇈", "⇈", 1.0, Code, KEY_PAGEUP, .scheme = 1},
  {"⇊", "⇊", 1.0, Code, KEY_PAGEDOWN, .scheme = 1},
  {"⇥", "⇥", 1.0, Code, KEY_END, .scheme = 1},
  {"CpL", "CpL", 1.0, Mod, CapsLock, .scheme = 1},
  {"", "", 3.0, Pad},
  {"<", "«", 1.0, Code, KEY_COMMA, 0, AltGr},
  {">", "»", 1.0, Code, KEY_DOT, 0, AltGr},
  {",", "'", 1.0, Code, KEY_COMMA, &layouts[ComposeMath]},
  {".", "?", 1.0, Code, KEY_DOT, &layouts[ComposePunctuation]},
  {"¡", "¿", 1.0, Code, KEY_MENU},
  {"Enter", "Enter", 1.0, Code, KEY_ENTER, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"Abc", "Abc", 1.0, BackLayer, .scheme = 1},
  {"⌨͕", "⌨͔", 1.0, NextLayer, .scheme = 1},
  {"Sup", "Sup", 1.0, Mod, Super, .scheme = 1},
  {"Alt", "Alt", 1.0, Mod, Alt, .scheme = 1},
  {"", "Tab", 2.0, Code, KEY_SPACE},
  {"", "", 3.0, Pad},
  {"", "Tab", 2.0, Code, KEY_SPACE},
  {"AGr", "AGr", 1.0, Mod, AltGr, .scheme = 1},
  {"←", "←", 1.0, Code, KEY_LEFT, .scheme = 1},
  {"↓", "↓", 1.0, Code, KEY_DOWN, .scheme = 1},
  {"→", "→", 1.0, Code, KEY_RIGHT, .scheme = 1},

  /* end of layout */
  {"", "", 0.0, Last},
};"""

start = content.index("static struct key keys_landscape[] = {")
end_marker = "static struct key keys_landscape_special[] = {"
end_special = content.index("};", content.index(end_marker)) + 2
content = content[:start] + split_landscape + content[end_special:]
with open("layout.mobintl.h", "w") as f:
    f.write(content)
EOF
  '';
})
