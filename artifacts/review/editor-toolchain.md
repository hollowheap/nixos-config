# Editor toolchain robustness review

## Verdict
- Biggest risk: `programs.neovim` and `programs.nvf` both install `bin/nvim`; `home.path` is a collision-checking `buildEnv`, so the Home Manager build can abort or shadow the nvf config entirely.
- Biggest missing option: no session/auto-restore owner, while nvf disables swap and backup by default → a crash loses unsaved buffers with no recovery path.
- Seam worth changing: `home/lib/toolchains.nix` is documented as the editor toolchain map, but only its `linters` block is consumed; the rest is decorative drift.

## Findings

### F1: Two packages provide `nvim`
- Current: `home/modules/programs/nvim/core.nix:11-17` enables `programs.neovim` and `programs.nvf`; `flake/default.nix:57` imports the nvf HM module.
- Gap: HM neovim adds `[cfg.finalPackage]` to `home.packages`; nvf adds its `symlinkJoin` package. Both expose `bin/nvim`. `home.path` uses `buildEnv` with `ignoreCollisions = false` and `checkCollisionContents = true`.
- Failure/impact: `home-manager switch` fails with a `bin/nvim` collision, or (if priorities resolve it) plain neovim shadows nvf, so mappings/LSP never load and state moves to a different `NVIM_APPNAME` dir.
- Config:
```nix
programs.nvf = { enable = true; defaultEditor = true; };
# remove programs.neovim; nvf sets EDITOR only
home.sessionVariables.VISUAL = "nvim";
```
- Source: https://github.com/NotAShelf/nvf/blob/main/flake/modules/home-manager.nix ; https://github.com/nix-community/home-manager/blob/master/modules/programs/neovim/default.nix ; https://github.com/nix-community/home-manager/blob/master/modules/home-environment.nix
- Default check: `home.packages` is a plain list with no dedupe; `buildEnv` defaults to aborting on differing collisions. Confidence: UNVERIFIED (build not run).

### F2: Diagnostics config is inert
- Current: `home/modules/programs/nvim/lsp.nix:54-72` sets `vim.diagnostics.config` and enables `nvim-lint`.
- Gap: nvf gates `vim.diagnostic.config` behind `vim.diagnostics.enable`; that option defaults false and is never set here. `nvim-lint` does not enable it.
- Failure/impact: the `●` prefix, spacing, `source = "if_many"` and `severity_sort` never apply; mixed severities render in insertion order.
- Config: `programs.nvf.settings.vim.diagnostics.enable = true;`
- Source: https://github.com/NotAShelf/nvf/blob/main/modules/neovim/init/diagnostics.nix
- Default check: nvf `mkEnableOption` → false; Neovim already defaults signs/underline/virtual text on. Confidence: verified.

### F3: Formatters installed, format-on-save never runs
- Current: `lsp.nix:14` sets `enableFormat = true`; `lsp.nix:30-52` nulls mappings but never sets `lsp.formatOnSave`.
- Gap: nvf's conform `format_on_save` default returns nil unless `vim.g.nvf_format_save` is true, and that flag comes from `vim.lsp.formatOnSave` (default false).
- Failure/impact: all conform formatters (alejandra, black, prettier, clang-format, shfmt, deno) are wired but only `<leader>lf` runs them; saved Nix/Markdown drifts. Blindly enabling will let `deno fmt` reflow Markdown prose.
- Config:
```nix
programs.nvf.settings.vim.lsp.formatOnSave = true;
# optionally drop markdown from conform formatters_by_ft
```
- Source: https://github.com/NotAShelf/nvf/blob/main/modules/plugins/formatter/conform-nvim/conform-nvim.nix ; https://github.com/NotAShelf/nvf/blob/main/modules/plugins/lsp/config.nix
- Default check: `formatOnSave` is `mkEnableOption` → false; lint-on-save and inlay hints are already on. Confidence: verified.

### F4: Keymaps shadowed by plugin defaults
- Current: `<leader>td` mapped to `Snacks.dim()` (`keymaps.nix:672-678`); nvf gitsigns default `<leader>td` is `toggleDeleted`. `<leader>ls` maps symbols (`keymaps.nix:591-597`); nvf `signatureHelp` default is `<leader>ls`. `<leader>y` is both a which-key group (`keymaps.nix:66`) and a direct mapping (`keymaps.nix:476`).
- Gap: gitsigns mappings are registered as lazy `keys` after nvf mappings; LSP signature mapping is buffer-local on `LspAttach`. `<leader>y` is a prefix of `<leader>yy`, so the exact mapping waits `timeoutlen`.
- Failure/impact: `<leader>td` toggles deleted lines instead of dimming; `<leader>ls` opens signature help in LSP buffers; `<leader>y` stalls ~1s before yanking.
- Config:
```nix
programs.nvf.settings.vim.git.gitsigns.mappings.toggleDeleted = null;
programs.nvf.settings.vim.lsp.mappings.signatureHelp = null;
# remove the `<leader>y` group entry or the direct `<leader>y` mapping
```
- Source: https://github.com/NotAShelf/nvf/blob/main/modules/plugins/git/gitsigns/gitsigns.nix ; https://github.com/NotAShelf/nvf/blob/main/modules/plugins/lsp/module.nix ; https://neovim.io/doc/user/map.html
- Default check: nvf defaults as cited; verified conflict (lazy key ordering is version-dependent).

### F5: `<leader>sn` calls a picker that does not exist
- Current: `keymaps.nix:724-728` calls `Snacks.picker.noice()`.
- Gap: snack's picker sources contain no `noice` source; noice.nvim, which could register it, is not enabled anywhere.
- Failure/impact: `<leader>sn` raises "attempt to call a nil value"; which-key advertises it as "Noice".
- Config:
```nix
# use an installed source
action = "function() Snacks.picker.notifications() end";
# or enable vim.ui.noice and keep the mapping
```
- Source: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
- Default check: n/a; source absence verified.

### F6: No session owner; crash recovery is off
- Current: `snacks.nix:51-56` adds a dashboard key `{ key = "s"; section = "session"; }`; `snacks.nix:64-89` sections omit `session`. No `vim.session.*` or `vim.projects.*` is enabled.
- Gap: snacks only renders that key when a session section exists and one of nvim-session-manager, possession, mini.sessions, or auto-session is installed; none are. nvf's `preventJunkFiles` defaults true, disabling swap, backup, and writebackup.
- Failure/impact: "Restore Session" is dead; after a crash, unsaved buffers are unrecoverable (no E325 conflict because there is no swap file).
- Config:
```nix
programs.nvf.settings.vim.mini.sessions.enable = true;
# snacks.nix: add { section = "session"; } to dashboard.sections
```
- Source: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/dashboard.lua ; https://github.com/NotAShelf/nvf/blob/main/modules/neovim/init/basic.nix ; https://github.com/NotAShelf/nvf/blob/main/modules/plugins/session/persisted/persisted.nix
- Default check: nvf `preventJunkFiles = true`; verified.

### F7: Clipboard yank/paste asymmetry and SSH failure
- Current: `core.nix:24-28` adds `wl-clipboard`; no `vim.clipboard.enable` or `vim.options.clipboard`; keymaps use `"+y` (`keymaps.nix:456-492`).
- Gap: with `'clipboard'` empty, `y`/`p` use the unnamed register; only explicit `"+` touches the system clipboard. Neovim auto-selects OSC52 only when `g:termfeatures.osc52` is set and `'clipboard'` is empty.
- Failure/impact: `<leader>y` then plain `p` pastes stale text. Over plain SSH/mosh (no `WAYLAND_DISPLAY`, no `TMUX`) `"+y` errors "clipboard: No provider"; tmux+pass-through works.
- Config:
```nix
programs.nvf.settings.vim.luaConfigRC.clipboard = ''
  if vim.env.WAYLAND_DISPLAY then vim.o.clipboard = "unnamedplus"
  elseif vim.env.SSH_TTY then vim.g.clipboard = "osc52" end
'';
```
- Source: https://github.com/NotAShelf/nvf/blob/main/modules/neovim/init/clipboard.nix ; https://github.com/neovim/neovim/blob/master/runtime/autoload/provider/clipboard.vim
- Default check: verified provider order; `termfeatures.osc52` is unset.

### F8: Document highlight and search pill are effectively dead
- Current: `lsp.nix:106-126` uses `CursorHold`/`CursorHoldI` for `document_highlight`; `ui.nix:206-215` renders a search-count pill only when `vim.v.hlsearch ~= 0`.
- Gap: `updatetime` is never set (Neovim default 4000 ms); `hlsearch` is never enabled (default off). `incsearch` does not set `hlsearch` after `<CR>`.
- Failure/impact: reference highlighting lags 4s; the lualine search pill never appears after a search.
- Config:
```nix
programs.nvf.settings.vim.options = { updatetime = 300; hlsearch = true; };
programs.nvf.settings.vim.hideSearchHighlight = true;
```
- Source: https://github.com/neovim/neovim/blob/master/src/nvim/options.lua ; https://neovim.io/doc/user/options.html
- Default check: `updatetime=4000`, `hlsearch` off; verified.

### F9: Toolchain map is mostly dead and `.sh` is half-covered
- Current: `home/lib/toolchains.nix:10-55` declares LSP, formatter, linter, debugger maps; only `editorToolchains.linters` is imported (`lsp.nix:7,68-70`) and only for `yaml`/`zsh`.
- Gap: `.lsp`, `.formatters`, `.debuggers` are unused. Header lines 3-8 claim the map is "passed via extraSpecialArgs", but `flake/default.nix:54` passes only `inputs`. nvf's zsh module sets `shfmt` for filetype `sh` but LSP filetypes `["zsh"]`, and no bash parser/linter is enabled.
- Failure/impact: map values can silently diverge from nvf; map/README lie about coverage; `.sh` files get formatting but no LSP, treesitter, or shellcheck.
- Config:
```nix
programs.nvf.settings.vim.diagnostics.nvim-lint.linters_by_ft =
  editorToolchains.linters;   # consume the map, or trim it
```
- Source: https://github.com/NotAShelf/nvf/blob/main/modules/plugins/languages/zsh.nix
- Default check: verified by repo grep and nvf source.

### F10: Language and prose coverage gaps
- Current: `lsp.nix:11-27` enables clang, nix, python, tsx, typescript, yaml, zsh, markdown.
- Gap: no Lua/JSON/TOML/Bash modules; nvf's typescript module registers LSP only for `typescript`/`javascript`, leaving `.jsx` (`javascriptreact`) uncovered; no spellcheck at all for Markdown/prose.
- Failure/impact: editing nvf's own injected Lua snippets, JSON/TOML data, and `.sh` scripts has no LSP, formatter, or linter; prose has no spell check.
- Config:
```nix
programs.nvf.settings.vim.languages = {
  lua.enable = true; bash.enable = true;
  json.enable = true; toml.enable = true;
};
programs.nvf.settings.vim.spellcheck = {
  enable = true;
  ignoredFiletypes = [ "toggleterm" "nix" "lua" "python" "c" "cpp"
    "typescript" "typescriptreact" "yaml" "zsh" "json" "toml" ];
};
```
- Source: https://github.com/NotAShelf/nvf/blob/main/modules/plugins/languages/typescript.nix ; https://github.com/NotAShelf/nvf/blob/main/modules/neovim/init/spellcheck.nix
- Default check: verified.

## Toolchain matrix
- Nix → LSP `nil` ✓ (preset, absolute `pkgs.nil`); formatter alejandra ✓; linters statix+deadnix ✓; DAP n/a; parser nix ✓.
- C/C++ → clangd ✓; clang-format ✓; clangtidy ✓; DAP lldb (`lldb-dap`) ✓; parsers c/cpp ✓.
- TS/JS → `typescript-language-server` ✓ for `typescript`/`javascript` only; prettier ✓; eslint_d ✓ (needs project config); DAP ✗; parsers ts/js ✓.
- TSX → `typescript-language-server` ✓; prettier ✓; biomejs ✓; DAP ✗; parser tsx ✓.
- Python → basedpyright ✓; black ✓; mypy ✓; debugpy ✓; parser python ✓.
- Lua → LSP ✗, formatter ✗, linter ✗; parser lua ✓ (nvf default grammar).
- Go → all ✗ (no gopls/gofmt/golangci-lint/delve/go parser).
- Rust → all ✗ (no rust-analyzer/rustfmt/codelldb/rust parser).
- JSON → all ✗ (no server, formatter, parser).
- YAML → yaml-language-server ✓; prettier ✓; yamllint ✓ via PATH (`lsp.nix:68-70` + `core.nix:25`); parser yaml ✓.
- TOML → all ✗.
- Markdown → marksman ✓; deno ✓; markdownlint-cli2 ✓; markview ✓; parsers markdown+inline ✓.
- No Mason: presets pin absolute store paths; only yamllint/zsh resolve through PATH.

## Failure modes
- nvf/nixpkgs bump breaks eval → HM switch aborts → old generation still boots; F1 makes a failed switch likely now.
- Missing formatter binary → presets use absolute paths; yamllint rides `extraPackages`, zsh rides user PATH.
- Treesitter parser after update → grammars are pinned via `nvim-treesitter.withPlugins`; no runtime install, only query/grammar skew on nvf bump.
- Clipboard over SSH → F7, unless `$TMUX` is set (tmux `set-clipboard on`, `tmux.nix:87`).
- Plugin keymap conflicts → F4, plus scattered ownership across five files.
- Slow startup → 11 `lazy=false` plugin entries plus avante/image.nvim; `vim.enableLuaLoader` is not enabled.
- Large-file freeze → covered: snacks `bigfile` and `quickfile` enabled (`snacks.nix:111-116`).
- Debug adapter missing → only C/C++ and Python have adapters; TS/Go/Rust have none.
- Diagram/image preview → `mermaid-cli` (Node+Chromium), `plantuml` (JRE), `graphviz`, `d2`, ImageMagick are always in nvim PATH (`diagrams.nix:4-10`); `image.nvim` backend is hardcoded `"kitty"`, works in Ghostty+tmux (`allow-passthrough on`) but fails over SSH/headless.
- Markdown preview → markview needs no Node; mermaid rendering does.
- Undo/shada loss → `NVIM_APPNAME=nvf` state dir; plain neovim (F1) uses a different one.
- Swap conflict → prevented by `swapfile=false`; crash loses the buffer instead.

## Seams
- `home/lib/toolchains.nix` vs `lsp.nix` language list: only linters consumed; no assertion ties map to nvf options.
- Keymap ownership split across `keymaps.nix`, `debugger.nix`, `diagrams.nix`, `preview.nix`, `quickfix.nix`; nvf defaults are selectively nulled (`lsp.nix:35-45`) and two were missed (`signatureHelp`, gitsigns `toggleDeleted`).
- Theme: base16 palette (`ui.nix:12-33`) plus wallust writing `~/.config/nvf/lua/wallust.lua` (`ui.nix:362-368`), loaded through a `package.path` append (`ui.nix:309-318`); SIGUSR1 reload is handled by the template.
- Editor env: `programs.neovim.defaultEditor` sets `EDITOR`+`VISUAL`; `programs.nvf.defaultEditor` sets only `EDITOR`.
- Project-local config: none; no `vim.additionalRuntimePaths`, no `exrc`; nvf documents `additionalRuntimePaths` for `~/.config/nvim` (https://nvf.notashelf.dev/faq.html).
- Git: gitsigns + snacks pickers only; no worktree UI/picker, no neogit/fugitive.
- Tests: `tests/home.nix:40-42` only greps diagram file existence; no eval check for LSP servers, formatters, or keymaps.

## Rejected defaults
- `compatible = false` → Neovim default already off.
- `ruler`, `showcmd`, `incsearch` → Neovim defaults already on.
- `number = true` → nvf `lineNumberMode = "relNumber"` already sets number+relativenumber.
- `wrap`, `expandtab` → Neovim/nvf defaults already on.
- `swapfile`/`backup` → nvf `preventJunkFiles` already disables both.
- `termguicolors` → Neovim auto-detects 24-bit; tmux sets `terminal-features ,*:RGB`.
- `signcolumn` → snacks `statuscolumn` renders signs; Neovim default `auto` is acceptable.

## Open questions
- Is `programs.neovim` intentionally kept as a fallback, or can nvf become the sole provider?
- Is silent format-on-save wanted for Nix/Markdown, given `deno fmt` reflows prose?
- Should `home/lib/toolchains.nix` become the consumed source of truth, or be trimmed to the linters it actually drives?
- Are Lua/JSON/TOML/Go/Rust edited often enough to justify their closure cost?
- Is editor-level session restore wanted on top of tmux-resurrect?
