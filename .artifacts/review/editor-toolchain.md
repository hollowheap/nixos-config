# V05: Editor Toolchain — Robustness Review

**User-visible outcome**: Neovim (`nvf`) launches cleanly with working LSP diagnostics, formatting, Treesitter, session persistence, clipboard, and diagram/image preview tools without conflicting providers or missing binaries.

**End-to-end verification commands & observed results**:
- `nix build .#homeConfigurations.hollowheap.config.programs.nvf.finalPackage --no-link`: **PASSED** (`/nix/store/iwpa0ik4pw84p7k1qbibq3kid2jiswlp-nvf-with-helpers`).
- `nvim --headless "+qa"` (built package): **PASSED** (exit `0`).
- `nix build .#checks.x86_64-linux.home --no-link`: **PASSED**.
- `test -f home/modules/programs/nvim/preview.nix`: **FAILED** (file deleted in commit `4712514`, breaking `R20` check).
- Headless conform check (`markdown` buffer): **FAILED** (`require('conform').list_formatters(b)` resolves `deno` despite `lib.mkForce [ ]` override).
- Headless dashboard session check (`Snacks.dashboard.open`): **FAILED** (`"Restore Session"` absent because `Snacks.dashboard` `have_plugin` expects `lazy.nvim`).

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. `keymaps.nix` remains 1,133 lines instead of domain co-location (`R20`); remapping `r` to `<Nop>` forces `nowait` autocmd workarounds in `snacks.nix:167-190`. |
| architecture | loaded | `home/modules/core/toolchain.nix` centralizes LSP/linter/toolchain contracts (`programs.neovim.enable = false`, `programs.nvf` sole provider); `completion.nix:37` hardcodes an impure home path. |
| api | loaded | `toolchain.formattersByFt.markdown = lib.mkForce [ ]` is bypassed because `nvfLanguages.markdown.enable = true` injects `languages.markdown.format.type = [ "deno" ]` into conform. |
| data | loaded | `mini.sessions` writes to `~/.local/share/nvf/session/Session.vim`, but `autoread = false` and broken dashboard `section = "session"` leave session restore inaccessible. |
| security | loaded | Unfree `diagram.nvim` is explicitly allowlisted; diagram/clipboard/trash tools (`d2`, `graphviz`, `mermaid-cli`, `plantuml`, `imagemagick`, `wl-clipboard`, `trash-cli`) bind via Nix store paths. |
| performance | loaded | Lazy-loading via `lz.n` (`diagram.nvim`, `image.nvim`, `helpview.nvim`), `updatetime = 300`, Snacks `bigfile`/`quickfile`; `enableLuaLoader` remains disabled (`false`). |
| tests | loaded | `R20` verify fails (`preview.nix` missing); `tests/home.nix` uses regex/file checks only with no runtime nvf or option checks. |
| ui | loaded | Which-key advertises 6 unbound `<leader>a*` mappings and dashboard drops `"Restore Session"`. Live GUI Kitty/image/diagram pixel rendering is **UNVERIFIED**. |

---

## Failure modes

### 1. [High] Markdown prose reflowed on save by `deno fmt` despite `lib.mkForce [ ]`
- **Current**: [home/modules/core/toolchain.nix:226-228](file:///home/hollowheap/repos/nixos-config/home/modules/core/toolchain.nix#L226-L228), [home/modules/programs/nvim/lsp.nix:18,22](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/lsp.nix#L18)
- **Gap**: `nvfLanguages.markdown.enable = true` with `enableFormat = true` lets `nvf`'s `languages.markdown` module inject `formatters_by_ft.markdown = [ "deno" ]` into `conform.nvim`, bypassing `toolchain.formattersByFt.markdown = lib.mkForce [ ]`.
- **Failure/impact + repro**: Saving any Markdown buffer (`:w` with `formatOnSave = true`) runs `deno fmt`, reflowing prose and bullet lists.
  ```bash
  nvim --headless -c "lua local c=require('conform'); local b=vim.api.nvim_create_buf(false,true); vim.bo[b].filetype='markdown'; for _,f in ipairs(c.list_formatters(b)) do print(f.name) end" -c "qa"
  # Output: deno
  ```
- **Config minimal shape**: Set `markdown.format.enable = false;` in `toolchain.nvfLanguages` ([home/modules/core/toolchain.nix](file:///home/hollowheap/repos/nixos-config/home/modules/core/toolchain.nix)).
- **Source**: `nvf` `modules/plugins/languages/markdown.nix` + `conform-nvim.nix`.
- **Default check**: `nvf` `format.enable` defaults to `vim.languages.enableFormat` (`true`).
- **Confidence**: Verified.

### 2. [High] Session restore missing from Snacks dashboard and unbound in keymaps (`R52`)
- **Current**: [home/modules/programs/nvim/snacks.nix:51-55](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/snacks.nix#L51-L55), [home/modules/programs/nvim/mini.nix:54](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/mini.nix#L54)
- **Gap**: Dashboard key `{ key = "s"; section = "session"; }` calls `Snacks.dashboard.have_plugin()`, which checks `lazy.nvim` (`lazy.core.config`), whereas `nvf` uses `lz.n`. The section returns `nil` and is omitted; `mini.sessions` has `autoread = false` and no restore keybind exists.
- **Failure/impact + repro**: `"Restore Session"` never renders on dashboard startup and no keymap exists to load saved sessions.
  ```bash
  nvim --headless -c "lua local b=vim.api.nvim_create_buf(false,true); Snacks.dashboard.open({buf=b}); print(table.concat(vim.api.nvim_buf_get_lines(b,0,-1,false), '\n'))" -c "qa" | grep -c "Restore Session"
  # Output: 0
  ```
- **Config minimal shape**: Use explicit `action = ":lua require('mini.sessions').read()"` on dashboard key `"s"` and bind `<leader>qs` in [home/modules/programs/nvim/keymaps.nix](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/keymaps.nix).
- **Source**: `snacks.nvim/lua/snacks/dashboard.lua`.
- **Default check**: Verified against built `nvf-with-helpers`.
- **Confidence**: Verified.

### 3. [Medium] Six ghost `<leader>a*` Avante mappings registered in `which-key` without actions
- **Current**: [home/modules/programs/nvim/keymaps.nix:54-63,890-901](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/keymaps.nix#L54-L63)
- **Gap**: `whichKey.register` advertises `<leader>aa`, `<leader>ae`, `<leader>at`, `<leader>af`, `<leader>ar`, `<leader>as`, while `vim.keymaps` only defines `<leader>an` and `<leader>ah`.
- **Failure/impact + repro**: Pressing those 6 keys triggers nothing (`vim.fn.maparg('<leader>aa', 'n')` returns `""`).
- **Config minimal shape**: Bind `<leader>aa` (`AvanteAsk`), `<leader>ae` (`AvanteEdit`), `<leader>at` (`AvanteToggle`), `<leader>af` (`AvanteFocus`), `<leader>ar` (`AvanteRefresh`), and remove unbound entries.
- **Source**: `avante.nvim` commands + `keymaps.nix`.
- **Default check**: Verified via headless `vim.fn.maparg`.
- **Confidence**: Verified.

### 4. [Medium] Avante ACP provider hardcodes impure `/home/hollowheap/repos/...` path
- **Current**: [home/modules/programs/nvim/completion.nix:37](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/completion.nix#L37)
- **Gap**: `acp_providers.pi.args` hardcodes `"/home/hollowheap/repos/my-pi-agent/packages/pi-acp/dist/main.js"`.
- **Failure/impact + repro**: Breaks for other usernames/hosts (`acervus`) or when the checkout path moves.
- **Config minimal shape**: Parameterize via `${config.home.homeDirectory}/repos/my-pi-agent/packages/pi-acp/dist/main.js` or package `pi-acp` via Nix.
- **Source**: `home/modules/programs/nvim/completion.nix:37`.
- **Default check**: Local config.
- **Confidence**: Verified.

### 5. [Medium] `R20` verification command references deleted `preview.nix`
- **Current**: [.artifacts/REQUIREMENTS.md:145](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md#L145)
- **Gap**: Commit `4712514` replaced `preview.nix` with `diagrams.nix` / `render-markdown-nvim`, but `R20` still checks `test -f home/modules/programs/nvim/preview.nix` (exit `1`).
- **Failure/impact + repro**: `R20` verify fails directly in shell.
- **Config minimal shape**: Update `R20` verify target to `diagrams.nix` alongside `quickfix.nix` and `editing.nix`.
- **Source**: Commit `47125141e28d649e0311058180b2a85f20962453`.
- **Default check**: Verified via `test -f`.
- **Confidence**: Verified.

### 6. [Low] `vim.enableLuaLoader` remains `false`, disabling Neovim bytecode startup cache
- **Current**: [home/modules/programs/nvim/core.nix:15-61](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/core.nix#L15-L61)
- **Gap**: `programs.nvf.settings.vim.enableLuaLoader` defaults to `false`.
- **Failure/impact + repro**: `nix eval --json .#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.enableLuaLoader` returns `false`.
- **Config minimal shape**: Set `enableLuaLoader = true;` in [home/modules/programs/nvim/core.nix](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/core.nix).
- **Source**: `nvf` `modules/neovim/init/basic.nix`, Neovim `:help vim.loader`.
- **Default check**: `nvf` defaults `enableLuaLoader` to `false`.
- **Confidence**: Verified.

### 7. [Low] Normal-mode `r` hijacked to `<Nop>` operator prefix requires `nowait` picker shims
- **Current**: [home/modules/programs/nvim/keymaps.nix:345-350](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/keymaps.nix#L345-L350), [home/modules/programs/nvim/snacks.nix:167-190](file:///home/hollowheap/repos/nixos-config/home/modules/programs/nvim/snacks.nix#L167-L190)
- **Gap**: Mapping `r` to `<Nop>` (`rr` replace) forced custom `FileType` autocmd `nowait` shims for Snacks picker rename actions (`nvim --headless -c "lua local m=vim.fn.maparg('r','n',false,true); print(m.rhs)" -c "qa"` -> `<Nop>`).
- **Failure/impact + repro**: Future plugin buffers binding `r` inherit conflicts unless manually shimmed.
- **Config minimal shape**: Either keep `nowait` shims on all custom picker filetypes or use a non-builtin operator prefix.
- **Source**: Commit `7c6c727b9a236cbbba58041eb13c9cce43da4456`.
- **Default check**: Standard Vim `r` replaces a single character.
- **Confidence**: Verified.

### 8. [Low] `tests/home.nix` checks static strings without evaluated/headless nvf assertions
- **Current**: [tests/home.nix:18-21,49-51](file:///home/hollowheap/repos/nixos-config/tests/home.nix#L18-L21)
- **Gap**: Asserts file presence and `rg` matches only (`checks.x86_64-linux.home` passes despite F1, F2, F3, F5).
- **Failure/impact + repro**: Option collisions and missing bindings pass CI checks silently.
- **Config minimal shape**: Assert `programs.nvf.enable == true`, `programs.neovim.enable == false`, and `languages.markdown.format.enable == false` via Nix eval.
- **Source**: `tests/home.nix`.
- **Default check**: Verified.
- **Confidence**: Verified.

---

## Seams

1. **`toolchain.nvfLanguages` vs `conform-nvim.setupOpts`**: `languages.markdown` overrides `formatters_by_ft` unless `markdown.format.enable = false`.
2. **`snacks.dashboard` vs `lz.n`**: Upstream `have_plugin` expects `lazy.nvim`, silently dropping `section = "session"` under `nvf`.
3. **Keymap Co-location (`R20`)**: Domain plugins vs 1,133-line `keymaps.nix` containing unbound `whichKey.register` entries.
4. **Wallust `SIGUSR1` Reload**: `programs.wallust.settings.templates.nvim` writes `wallust.lua` and signals Neovim via `pkill -SIGUSR1 nvim` (`ui.nix:308-358`).
5. **Avante External ACP Path**: Mutable `/home/hollowheap/repos/my-pi-agent/...` path in `completion.nix:37`.

---

## Rejected defaults

- `programs.neovim.enable = true`: Rejected (`false`; `programs.nvf` owns editor config).
- `swapfile = true` / `backup = true`: Rejected via `preventJunkFiles = true`.
- Redundant `compatible = false`, `termguicolors = true`, `ruler`, `showcmd`, `incsearch`, `expandtab`: Covered by Neovim/`nvf` defaults.

---

## Blocking Design Forks

1. **Markdown Format-on-Save Policy (`F1`)** → route to `/design`: disable `markdown.format.enable = false` in `nvfLanguages` vs configure a prose-preserving formatter (`prettier --prose-wrap preserve`).
2. **Session Restore Lifecycle (`F2`)** → route to `/design`: manual dashboard action + `<leader>qs` binding vs automatic `mini.sessions` `autoread = true` on empty launch.
3. **Normal-mode `r` Operator Prefix (`F7`)** → route to `/design`: retain `r` → `<Nop>` (`rr` replace) with `nowait` shims vs moving operator prefix off built-in `r`.
