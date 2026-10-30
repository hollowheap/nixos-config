{
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
  modes = {
    nvo = [
      "n"
      "v"
      "o"
    ];
    nv = [
      "n"
      "v"
    ];
  };
in
{
  programs.nvf.settings.vim = {
    binds = {
      whichKey = {
        enable = true;
        setupOpts = {
          preset = "helix";
          filter = mkLuaInline "function(mapping) if mapping.lhs == 'r' and mapping.desc == 'Replace' then return false end return mapping.desc and mapping.desc ~= '' and mapping.desc ~= '<Nop>' and not mapping.hidden end";
        };
        register = {
          "p" = "Paste after";
          "P" = "Paste before";
          "u" = "Undo";
          "U" = "Redo";

          "d" = "+Delete";
          "y" = "+Yank";
          "z" = "+Fold";

          "s" = "+Surround";
          "g" = "+Go to";
          "r" = "+Operator";
          "rc" = "+Comment";
          "rd" = "Go to definition";
          "rD" = "Go to declaration";
          "re" = "Evaluate";
          "rx" = "Exchange";
          "rm" = "Multiply";
          "ro" = "Replace";
          "rs" = "Sort";
          "rw" = "Search selection forward";
          "rq" = "Search selection backward";

          "<leader>" = "+Menu";

          "<leader>a" = "+Agent";
          "<leader>aa" = "Ask prompt";
          "<leader>ae" = "Edit selection";
          "<leader>at" = "Toggle sidebar";
          "<leader>af" = "Focus sidebar";
          "<leader>ar" = "Refresh repomap";
          "<leader>an" = "New chat session";
          "<leader>ah" = "Select history";
          "<leader>as" = "Toggle suggestion";

          "<leader>l" = "+LSP";

          "<leader>s" = "+Search";
          "<leader>sx" = "+Diagnostics";

          "<leader>w" = "+Window";
          "<leader>v" = "+Visits";

          "<leader>q" = "+Quit";

          "<leader>t" = "+Toggle";
          "<leader>tz" = "Toggle Zen Mode";
          "<leader>td" = "Toggle Scope Dimming";
          "<leader>tZ" = "Toggle Zoom";
        };
      };
      hardtime-nvim = {
        enable = true;
        setupOpts = {
          disable_mouse = false;
          max_count = 2;
          hint = true;
          notification = true;
          disabled_keys = {
            "<Up>" = { };
            "<Down>" = { };
            "<Left>" = { };
            "<Right>" = { };
          };
          disabled_filetypes = [
            "qf"
            "netrw"
            "NvimTree"
            "lazy"
            "mason"
            "oil"
            "minifiles"
            "snacks_picker_input"
            "snacks_picker_list"
            "snacks_notif"
            "trouble"
            "help"
            "man"
            "gitcommit"
            "checkhealth"
            "dap-repl"
          ];
          hints = {
            "0i" = {
              message = mkLuaInline "function() return 'Use I instead of 0i' end";
              length = 2;
            };
            "0a" = {
              message = mkLuaInline "function() return 'Use I instead of 0a' end";
              length = 2;
            };
            "ddO" = {
              message = mkLuaInline "function() return 'Use cc or S instead of ddO' end";
              length = 3;
            };
            "ddo" = {
              message = mkLuaInline "function() return 'Use cc or S instead of ddo' end";
              length = 3;
            };
            "yyp" = {
              message = mkLuaInline "function() return 'Use rm (mini.operators.multiply) instead of yyp' end";
              length = 3;
            };
            "[w][w][w]" = {
              message = mkLuaInline "function() return 'Use f/t or search (/) instead of repeated w' end";
              length = 3;
            };
            "[b][b][b]" = {
              message = mkLuaInline "function() return 'Use F/T or search (?) instead of repeated b' end";
              length = 3;
            };
            "[j+][j+][j+]" = {
              message = mkLuaInline "function() return 'Use <C-d>, /search, or relative line jump instead of repeated j' end";
              length = 3;
            };
            "[k-][k-][k-]" = {
              message = mkLuaInline "function() return 'Use <C-u>, ?search, or relative line jump instead of repeated k' end";
              length = 3;
            };
          };
        };
      };
    };

    luaConfigRC.keymapRelocationsAndClears = lib.hm.dag.entryBefore [ "mappings" ] ''
      local set = vim.keymap.set
      local nop = function(m, l)
        set(m, l, "<Nop>", { noremap = true, desc = "<Nop>" })
      end
      local function del(m, l, o)
        for _, mode in ipairs(type(m) == "table" and m or { m }) do
          pcall(vim.keymap.del, mode, l, o)
        end
      end
      local function copy(mode, from, to, desc_override)
        local m = vim.fn.maparg(from, mode, false, true)
        if next(m) == nil then return end
        set(mode, to, m.callback or m.rhs, {
          expr = m.expr == 1,
          remap = m.noremap == 0,
          desc = desc_override or m.desc,
        })
      end

      -- 1. Relocations (copy with maparg, then delete original) BEFORE clears
      copy("n", "gc", "rc", "Comment operator")
      copy("x", "gc", "rc", "Comment selection")
      del({ "n", "x" }, "gc")

      copy("n", "gcc", "rcc", "Comment line")
      del("n", "gcc")

      copy("o", "gc", "ic", "Inner comment")
      copy("o", "gc", "ac", "Around comment")
      del("o", "gc")

      copy("n", "gx", "<leader>x", "Open URI under cursor")
      copy("x", "gx", "<leader>x", "Open URI in selection")
      del({ "n", "x" }, "gx")

      copy("x", "*", "rw", "Search selection forward")
      copy("x", "#", "rq", "Search selection backward")
      del("x", "*")
      del("x", "#")

      -- 2. Delete default LSP mappings
      for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx", "gO" }) do
        del({ "n", "x" }, lhs)
      end
      del("i", "<C-s>")

      -- 3. Cleared with <Nop>
      for _, lhs in ipairs({
        "gq", "gw", "*", "#", "g*", "g#", "gI", "gR", "gQ", "g&", "gs", "g8",
        "gu", "gU", "g~", "g?", "gv",
        "ga", "gA",
      }) do
        nop({ "n", "v" }, lhs)
      end

      -- r is the +Operator prefix; map bare r to <Nop> so it never triggers default replace-char
      set({ "n", "v" }, "r", "<Nop>", { noremap = true, desc = "+Operator" })

      -- gi and go are mapped in normal mode to jumplist newer/older; clear in visual mode
      nop("v", "gi")
      nop("v", "go")

      for _, lhs in ipairs({ "gn", "gN", "gg", "G", "m", "'", "`", "<C-e>", "<C-y>", "ge", "gE", "gS" }) do
        nop({ "n", "v", "o" }, lhs)
      end

      for _, lhs in ipairs({ "g~~", "guu", "gUU", "g??", "<C-r>" }) do
        nop("n", lhs)
      end

      for _, lhs in ipairs({ "aB", "iB" }) do
        nop({ "v", "o" }, lhs)
      end

      for _, lhs in ipairs({ "<C-w>", "<C-u>" }) do
        nop("i", lhs)
      end
    '';

    keymaps = [
      # Motions
      {
        key = "H";
        mode = modes.nvo;
        action = "^";
        desc = "Beginning of line";
      }
      {
        key = "L";
        mode = modes.nvo;
        action = "$";
        desc = "End of line";
      }
      {
        key = "gH";
        mode = modes.nvo;
        action = "g^";
        desc = "Display line start";
      }
      {
        key = "gL";
        mode = modes.nvo;
        action = "g$";
        desc = "Display line end";
      }
      {
        key = "J";
        mode = modes.nv;
        action = "<C-d>zz";
        desc = "Scroll down and center";
      }
      {
        key = "K";
        mode = modes.nv;
        action = "<C-u>zz";
        desc = "Scroll up and center";
      }
      {
        key = "gj";
        mode = modes.nv;
        action = "Gzz";
        desc = "Bottom of file";
      }
      {
        key = "gk";
        mode = modes.nv;
        action = "ggzz";
        desc = "Top of file";
      }
      {
        key = "gj";
        mode = "o";
        action = "G";
        desc = "Bottom of file";
      }
      {
        key = "gk";
        mode = "o";
        action = "gg";
        desc = "Top of file";
      }
      {
        key = "gJ";
        mode = modes.nvo;
        action = "gj";
        desc = "Display line down";
      }
      {
        key = "gK";
        mode = modes.nvo;
        action = "gk";
        desc = "Display line up";
      }
      {
        key = "go";
        mode = "n";
        action = "<C-o>";
        desc = "Jump back (older)";
      }
      {
        key = "gi";
        mode = "n";
        action = "<C-i>";
        desc = "Jump forward (newer)";
      }
      {
        key = "U";
        mode = "n";
        action = "<C-r>";
        desc = "Redo";
      }
      {
        key = "Y";
        mode = "n";
        action = "y$";
        desc = "Yank to end of line";
      }
      {
        key = "x";
        mode = modes.nv;
        action = "\"_x";
        desc = "Delete without yank";
      }
      {
        key = "X";
        mode = modes.nv;
        action = "\"_X";
        desc = "Delete without yank (backwards)";
      }

      # The r family
      {
        key = "rr";
        mode = modes.nv;
        action = "r";
        desc = "Replace character";
      }
      {
        key = "rR";
        mode = modes.nv;
        action = "R";
        desc = "Replace mode";
      }
      {
        key = "r~";
        mode = modes.nv;
        action = "g~";
        desc = "Toggle case";
      }
      {
        key = "r~~";
        mode = "n";
        action = "g~~";
        desc = "Toggle case line";
      }
      {
        key = "ru";
        mode = modes.nv;
        action = "gu";
        desc = "Lowercase";
      }
      {
        key = "ruu";
        mode = "n";
        action = "guu";
        desc = "Lowercase line";
      }
      {
        key = "rU";
        mode = modes.nv;
        action = "gU";
        desc = "Uppercase";
      }
      {
        key = "rUU";
        mode = "n";
        action = "gUU";
        desc = "Uppercase line";
      }
      {
        key = "r?";
        mode = modes.nv;
        action = "g?";
        desc = "ROT13 encoding";
      }
      {
        key = "r??";
        mode = "n";
        action = "g??";
        desc = "ROT13 line";
      }
      {
        key = "rw";
        mode = "n";
        action = "*";
        desc = "Search word forward";
      }
      {
        key = "rq";
        mode = "n";
        action = "#";
        desc = "Search word backward";
      }
      {
        key = "rp";
        mode = "n";
        action = "gp";
        desc = "Put after and leave cursor";
      }
      {
        key = "rP";
        mode = "n";
        action = "gP";
        desc = "Put before and leave cursor";
      }
      {
        key = "rv";
        mode = modes.nv;
        action = "gv";
        desc = "Reselect visual area";
      }
      {
        key = "rn";
        mode = modes.nvo;
        action = "gn";
        desc = "Search forward and select";
      }
      {
        key = "rN";
        mode = modes.nvo;
        action = "gN";
        desc = "Search backward and select";
      }
      {
        key = "r8";
        mode = "n";
        action = "g8";
        desc = "Print hex UTF-8 bytes";
      }
      {
        key = "ry";
        mode = modes.nv;
        action = "\"+y";
        desc = "Yank to system clipboard";
      }
      {
        key = "ryy";
        mode = "n";
        action = "\"+yy";
        desc = "Yank line to system clipboard";
      }
      {
        key = "rY";
        mode = modes.nv;
        action = "\"+y$";
        desc = "Yank to EOL to system clipboard";
      }

      # Clipboard yank & paste under <leader>
      {
        key = "<leader>yy";
        mode = "n";
        action = "\"+yy";
        desc = "Yank line to system clipboard";
      }
      {
        key = "<leader>Y";
        mode = modes.nv;
        action = "\"+y$";
        desc = "Yank to EOL to system clipboard";
      }

      # Clipboard paste & Quit
      {
        key = "<leader>p";
        mode = modes.nvo;
        action = "\"+p";
        desc = "Paste after from clipboard";
      }
      {
        key = "<leader>P";
        mode = modes.nvo;
        action = "\"+P";
        desc = "Paste before from clipboard";
      }
      {
        key = "<leader>qw";
        mode = modes.nv;
        action = "<cmd>wqa<cr>";
        desc = "Quit and save";
      }
      {
        key = "<leader>qq";
        mode = modes.nvo;
        action = "<cmd>qa!<cr>";
        desc = "Quit without saving";
      }

      # LSP under <leader>l
      {
        key = "<leader>lh";
        lua = true;
        action = "function() vim.lsp.buf.hover() end";
        mode = "n";
        desc = "Hover";
      }
      {
        key = "<leader>lhh";
        lua = true;
        action = "function() vim.lsp.buf.hover(); vim.defer_fn(function() vim.lsp.buf.hover() end, 200) end";
        mode = "n";
        desc = "Hover and focus float";
      }
      {
        key = "<leader>ln";
        lua = true;
        action = "function() vim.lsp.buf.rename() end";
        mode = "n";
        desc = "Rename symbol";
      }
      {
        key = "<leader>la";
        lua = true;
        action = "function() vim.lsp.buf.code_action() end";
        mode = "n";
        desc = "Code action";
      }
      {
        key = "<leader>ld";
        lua = true;
        action = "function() Snacks.picker.lsp_definitions() end";
        mode = "n";
        desc = "Go to definition [snacks]";
      }
      {
        key = "<leader>lD";
        lua = true;
        action = "function() Snacks.picker.lsp_declarations() end";
        mode = "n";
        desc = "Go to declaration [snacks]";
      }
      {
        key = "<leader>lr";
        lua = true;
        action = "function() Snacks.picker.lsp_references() end";
        mode = "n";
        desc = "Find references [snacks]";
      }
      {
        key = "<leader>li";
        lua = true;
        action = "function() Snacks.picker.lsp_implementations() end";
        mode = "n";
        desc = "Go to implementation [snacks]";
      }
      {
        key = "<leader>lt";
        lua = true;
        action = "function() Snacks.picker.lsp_type_definitions() end";
        mode = "n";
        desc = "Go to type definition [snacks]";
      }
      {
        key = "<leader>lo";
        lua = true;
        action = "function() Snacks.picker.lsp_symbols() end";
        mode = "n";
        desc = "Document symbols [snacks]";
      }
      {
        key = "<leader>ls";
        lua = true;
        action = "function() Snacks.picker.lsp_symbols() end";
        mode = "n";
        desc = "Document symbols [snacks]";
      }
      {
        key = "<leader>lS";
        lua = true;
        action = "function() Snacks.picker.lsp_workspace_symbols() end";
        mode = "n";
        desc = "Workspace symbols [snacks]";
      }
      {
        key = "<leader>lf";
        lua = true;
        action = "function() local ok, conform = pcall(require, 'conform'); if ok then conform.format({ async = true }) else vim.lsp.buf.format({ async = true }) end end";
        mode = "n";
        desc = "Format buffer";
      }
      {
        key = "<leader>lx";
        lua = true;
        action = "function() vim.lsp.codelens.run() end";
        mode = "n";
        desc = "Run codelens";
      }
      {
        key = "<leader>lc";
        lua = true;
        action = "function() Snacks.picker.lsp_incoming_calls() end";
        mode = "n";
        desc = "Incoming calls [snacks]";
      }
      {
        key = "<leader>lC";
        lua = true;
        action = "function() Snacks.picker.lsp_outgoing_calls() end";
        mode = "n";
        desc = "Outgoing calls [snacks]";
      }
      {
        key = "<leader>ly";
        lua = true;
        action = "function() vim.lsp.buf.typehierarchy('supertypes') end";
        mode = "n";
        desc = "Type hierarchy (supertypes)";
      }
      {
        key = "<leader>lY";
        lua = true;
        action = "function() vim.lsp.buf.typehierarchy('subtypes') end";
        mode = "n";
        desc = "Type hierarchy (subtypes)";
      }

      # Operator actions (rd = definition, rD = declaration)
      {
        key = "rd";
        lua = true;
        action = "function() Snacks.picker.lsp_definitions() end";
        mode = "n";
        desc = "Go to definition [snacks]";
      }
      {
        key = "rD";
        lua = true;
        action = "function() Snacks.picker.lsp_declarations() end";
        mode = "n";
        desc = "Go to declaration [snacks]";
      }

      # Toggles under <leader>t (Zen & Twilight)
      {
        key = "<leader>tz";
        lua = true;
        action = "function() Snacks.zen() end";
        mode = "n";
        desc = "Toggle Zen Mode [snacks]";
      }
      {
        key = "<leader>td";
        lua = true;
        action = "function() Snacks.dim() end";
        mode = "n";
        desc = "Toggle Scope Dimming [snacks]";
      }
      {
        key = "<leader>tZ";
        lua = true;
        action = "function() Snacks.zen.zoom() end";
        mode = "n";
        desc = "Toggle Window Zoom [snacks]";
      }

      # Core & Snacks Pickers under <leader>s
      {
        key = "<leader>e";
        lua = true;
        action = "function() Snacks.explorer() end";
        mode = modes.nv;
        desc = "Explorer";
      }
      {
        key = "<leader>f";
        lua = true;
        action = "function() Snacks.picker.files() end";
        mode = modes.nv;
        desc = "Find Files";
      }
      {
        key = "<leader>sf";
        lua = true;
        action = "function() Snacks.picker.files() end";
        mode = modes.nv;
        desc = "Find Files";
      }
      {
        key = "<leader>sg";
        lua = true;
        action = "function() Snacks.picker.grep() end";
        mode = modes.nv;
        desc = "Live Grep";
      }
      {
        key = "<leader>sb";
        lua = true;
        action = "function() Snacks.picker.buffers() end";
        mode = modes.nv;
        desc = "Buffers";
      }
      {
        key = "<leader>sn";
        lua = true;
        action = "function() Snacks.picker.notifications() end";
        mode = modes.nv;
        desc = "Notifications";
      }
      {
        key = "<leader>sd";
        lua = true;
        action = "function() Snacks.picker.diagnostics_buffer() end";
        mode = modes.nv;
        desc = "Diagnostics (buffer) [snacks]";
      }
      {
        key = "<leader>sD";
        lua = true;
        action = "function() Snacks.picker.diagnostics() end";
        mode = modes.nv;
        desc = "Diagnostics (workspace) [snacks]";
      }
      {
        key = "<leader>sl";
        lua = true;
        action = "function() Snacks.picker.loclist() end";
        mode = "n";
        desc = "Location List [snacks]";
      }
      {
        key = "<leader>sq";
        lua = true;
        action = "function() Snacks.picker.qflist() end";
        mode = "n";
        desc = "Quickfix List [snacks]";
      }
      {
        key = "<leader>sc";
        lua = true;
        action = "function() Snacks.picker.lsp_incoming_calls() end";
        mode = "n";
        desc = "LSP incoming calls [snacks]";
      }
      {
        key = "<leader>sC";
        lua = true;
        action = "function() Snacks.picker.lsp_outgoing_calls() end";
        mode = "n";
        desc = "LSP outgoing calls [snacks]";
      }
      {
        key = "<leader>sr";
        lua = true;
        action = "function() Snacks.picker.registers() end";
        mode = "n";
        desc = "Registers [snacks]";
      }
      {
        key = "<leader>sp";
        lua = true;
        action = "function() Snacks.profiler.pick() end";
        mode = "n";
        desc = "Profiler Picker [snacks]";
      }

      # Window Management under <leader>w and Smart-Splits
      {
        key = "<leader>ws";
        mode = "n";
        action = "<cmd>split<cr>";
        desc = "Horizontal split";
      }
      {
        key = "<leader>wv";
        mode = "n";
        action = "<cmd>vsplit<cr>";
        desc = "Vertical split";
      }
      {
        key = "<leader>wc";
        mode = "n";
        action = "<cmd>close<cr>";
        desc = "Close window";
      }
      {
        key = "<leader>wo";
        mode = "n";
        action = "<cmd>only<cr>";
        desc = "Close other windows";
      }
      {
        key = "<leader>w=";
        mode = "n";
        action = "<C-w>=";
        desc = "Balance window sizes";
      }
      {
        key = "<leader>wh";
        lua = true;
        action = "function() require('smart-splits').move_cursor_left() end";
        mode = "n";
        desc = "Focus left window";
      }
      {
        key = "<leader>wj";
        lua = true;
        action = "function() require('smart-splits').move_cursor_down() end";
        mode = "n";
        desc = "Focus below window";
      }
      {
        key = "<leader>wk";
        lua = true;
        action = "function() require('smart-splits').move_cursor_up() end";
        mode = "n";
        desc = "Focus above window";
      }
      {
        key = "<leader>wl";
        lua = true;
        action = "function() require('smart-splits').move_cursor_right() end";
        mode = "n";
        desc = "Focus right window";
      }
      {
        key = "<leader>wH";
        lua = true;
        action = "function() require('smart-splits').swap_buf_left() end";
        mode = "n";
        desc = "Swap buffer left";
      }
      {
        key = "<leader>wJ";
        lua = true;
        action = "function() require('smart-splits').swap_buf_down() end";
        mode = "n";
        desc = "Swap buffer down";
      }
      {
        key = "<leader>wK";
        lua = true;
        action = "function() require('smart-splits').swap_buf_up() end";
        mode = "n";
        desc = "Swap buffer up";
      }
      {
        key = "<leader>wL";
        lua = true;
        action = "function() require('smart-splits').swap_buf_right() end";
        mode = "n";
        desc = "Swap buffer right";
      }

      {
        key = "<C-h>";
        lua = true;
        action = "function() require('smart-splits').move_cursor_left() end";
        mode = modes.nvo;
        desc = "Focus Left Window/Pane";
      }
      {
        key = "<C-j>";
        lua = true;
        action = "function() require('smart-splits').move_cursor_down() end";
        mode = modes.nvo;
        desc = "Focus Below Window/Pane";
      }
      {
        key = "<C-k>";
        lua = true;
        action = "function() require('smart-splits').move_cursor_up() end";
        mode = modes.nvo;
        desc = "Focus Above Window/Pane";
      }
      {
        key = "<C-l>";
        lua = true;
        action = "function() require('smart-splits').move_cursor_right() end";
        mode = modes.nvo;
        desc = "Focus Right Window/Pane";
      }
      {
        key = "<M-h>";
        lua = true;
        action = "function() require('smart-splits').resize_left() end";
        mode = "n";
        desc = "Resize Window Left";
      }
      {
        key = "<M-j>";
        lua = true;
        action = "function() require('smart-splits').resize_down() end";
        mode = "n";
        desc = "Resize Window Down";
      }
      {
        key = "<M-k>";
        lua = true;
        action = "function() require('smart-splits').resize_up() end";
        mode = "n";
        desc = "Resize Window Up";
      }
      {
        key = "<M-l>";
        lua = true;
        action = "function() require('smart-splits').resize_right() end";
        mode = "n";
        desc = "Resize Window Right";
      }

      # mini.visits under <leader>v (Harpoon-style workflow)
      {
        key = "<leader>va";
        lua = true;
        action = "function() MiniVisits.add_label('core') end";
        mode = "n";
        desc = "Add 'core' visit label";
      }
      {
        key = "<leader>vr";
        lua = true;
        action = "function() MiniVisits.remove_label('core') end";
        mode = "n";
        desc = "Remove 'core' visit label";
      }
      {
        key = "<leader>vv";
        lua = true;
        action = "function() MiniVisits.select_path() end";
        mode = "n";
        desc = "Select visited path (cwd)";
      }
      {
        key = "<leader>vV";
        lua = true;
        action = "function() MiniVisits.select_path('') end";
        mode = "n";
        desc = "Select visited path (global)";
      }
      {
        key = "<leader>v1";
        lua = true;
        action = "function() local p = MiniVisits.list_paths(nil, { filter = MiniVisits.gen_filter.this_session() })[1] or MiniVisits.list_paths()[1]; if p then vim.cmd.edit(vim.fn.fnameescape(p)) end end";
        mode = "n";
        desc = "Jump to visit 1";
      }
      {
        key = "<leader>v2";
        lua = true;
        action = "function() local p = MiniVisits.list_paths(nil, { filter = MiniVisits.gen_filter.this_session() })[2] or MiniVisits.list_paths()[2]; if p then vim.cmd.edit(vim.fn.fnameescape(p)) end end";
        mode = "n";
        desc = "Jump to visit 2";
      }
      {
        key = "<leader>v3";
        lua = true;
        action = "function() local p = MiniVisits.list_paths(nil, { filter = MiniVisits.gen_filter.this_session() })[3] or MiniVisits.list_paths()[3]; if p then vim.cmd.edit(vim.fn.fnameescape(p)) end end";
        mode = "n";
        desc = "Jump to visit 3";
      }
      {
        key = "<leader>v4";
        lua = true;
        action = "function() local p = MiniVisits.list_paths(nil, { filter = MiniVisits.gen_filter.this_session() })[4] or MiniVisits.list_paths()[4]; if p then vim.cmd.edit(vim.fn.fnameescape(p)) end end";
        mode = "n";
        desc = "Jump to visit 4";
      }
    ];

    luaConfigRC.which-key = ''
      local wk = require("which-key")
      wk.add({
        { "r", group = "Operator" },
        { "rc", group = "Comment" },
        { "rcc", desc = "Comment line" },
        { "rd", desc = "Go to definition" },
        { "rD", desc = "Go to declaration" },
        { "re", desc = "Evaluate" },
        { "rx", desc = "Exchange" },
        { "rm", desc = "Multiply" },
        { "ro", desc = "Replace" },
        { "rs", desc = "Sort" },
        { "rw", desc = "Search selection forward" },
        { "rq", desc = "Search selection backward" },
        { "<C-r>", hidden = true },
        { "<C-e>", hidden = true },
        { "<C-y>", hidden = true },
        { "ge",    hidden = true },
        { "gE",    hidden = true },
        { "gg",    hidden = true },
        { "G",     hidden = true },
      })
    '';
  };
}
