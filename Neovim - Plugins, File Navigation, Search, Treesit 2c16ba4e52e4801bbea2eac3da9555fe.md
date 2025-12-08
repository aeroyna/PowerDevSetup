# Neovim - Plugins, File Navigation, Search, Treesitter, LSP, Workflow

## **1. Plugin ecosystem mindset**

Neovim starts minimal. Everything advanced comes from plugins.

What plugins we installed:

- `lazy.nvim` → plugin manager
- `nvim-tree` → file tree
- `telescope.nvim` → fuzzy search
- `nvim-lualine` → status line
- `nvim-treesitter` → syntax + indent
- `nvim-lspconfig` → LSP support

Each plugin adds capabilities on top of the “vim core”.

---

## **2. lazy.nvim basics**

`lazy.nvim` manages installation and updates.

Inside Neovim:

```
:Lazy

```

Actions:

- Install plugins on first run automatically
- Use `:Lazy sync` to install/upgrade
- Use `:Lazy clean` to remove unused

You rarely need to touch this; it handles itself.

---

## **3. nvim-tree (File explorer)**

Open and browse project files visually.

Key:

```
<leader>e        (Space + e)

```

Useful actions inside the tree:

- Enter = open file
- `a` = create file
- `r` = rename
- `d` = delete

Close again with `<leader>e`.

This replaces constant `:e filename` commands.

---

## **4. Telescope (Fuzzy finder)**

Think of Telescope as “search everything”.

Main shortcuts:

```
<leader>ff   find files
<leader>fg   live grep in project
<leader>fb   list open buffers
<leader>fh   help tags

```

Example:

- Press `<leader>ff`
- Type part of filename
- Hit Enter → instantly jump there

Similarly `<leader>fg` searches inside files.

This is extremely powerful for large projects.

---

## **5. Treesitter**

Treesitter gives smarter syntax highlighting and indentation.

Installed languages:

- C, C++, Lua, JSON, YAML, Markdown, Bash

Updates syntax parsers:

```
:TSUpdate

```

Treesitter is Neovim’s modern syntax engine (far better indentation than old regex-based highlighting).

---

## **6. LSP – what it actually gives you**

LSP = Language Server Protocol

Neovim acts as a client; the server (clangd) provides intelligence.

LSP features:

- Go to definition
- Hover docs
- Code actions
- Rename symbol
- Diagnostics (errors/warnings)
- Jump to references
- Autocomplete (later via plugins)

---

## **7. clangd (C/C++ language server)**

We installed it system-wide:

```
sudo apt install clangd

```

Neovim auto-starts clangd when opening `.cpp` or `.h` files.

Check LSP status:

```
:LspInfo

```

---

## **8. Practical C++ LSP keymaps**

Inside C++ buffers:

Navigation:

```
gd        go to definition
gi        go to implementation
gr        references

```

Understanding:

```
K         hover documentation

```

Diagnostics:

```
[d        previous diagnostic
]d        next diagnostic

```

Refactor:

```
<leader>rn    rename symbol
<leader>ca    code action (apply fixes)

```

---

## **9. Typical project workflow in Neovim**

Inside your project directory:

```
nvim .

```

Useful flow:

1. `<leader>e` → browse files, open a `.cpp`
2. `<leader>ff` → jump to another file fast
3. `gd` → navigate to definition
4. `gr` → find usage
5. `K` → inspect type/hover info
6. Introduce a bug, use `[d` and `]d` to locate diagnostics
7. `<leader>rn` to rename functions or variables across the project
8. Use splits `:vsp` and `Ctrl+h/j/k/l` to view multiple files side-by-side

This is how you “IDE” without a GUI.

---

## **10. How to compile / run**

Inside Neovim:

```
:sp        (split window)
:terminal  (open terminal)

```

Use your usual commands (make, cmake, ninja, g++, etc).

Or just open a terminal outside Neovim; either works.

---

## **11. Learning habits**

Spend time learning:

- Movements (`w`, `b`, `e`, `0`, `$`, `gg`, `G`)
- Operators (`d`, `c`, `y`)
- Text objects (`iw`, `i"`, `i)`)
- Visual modes (`v`, `V`, `Ctrl+v`)

Every week:

- Replace one mouse action with a keyboard motion
- Replace one search with Telescope
- Replace one rename with `<leader>rn`

Gradually your hands will default to “Neovim mode”.

---

## **12. Next upgrades (future topics)**

Once comfortable:

- Autocompletion (nvim-cmp)
- Formatting (clang-format, format on save)
- Git integration (gitsigns)
- Debugging (DAP)
- Language-specific configs (python, Rust, Java, etc)

All stack cleanly on top of the current base.

---

## **13. Mental model summary**

Neovim is:

- A text manipulation language (Normal mode)
- A navigation engine (motions)
- A code intelligence frontend (LSP)
- A fuzzy search system (Telescope)
- A structured syntax system (Treesitter)

Plugins tie it all together. You’re essentially building your own IDE from small, powerful blocks.