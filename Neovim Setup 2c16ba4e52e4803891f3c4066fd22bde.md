# Neovim Setup

## 0. Environment

- Host: Windows (ARM)
- Dev: WSL (Ubuntu on ARM)
- Goal: Neovim with:
    - Modern UI (status line, file tree, fuzzy finder, Treesitter)
    - C/C++ LSP using `clangd`
    - Plugin management via `lazy.nvim`
- Neovim version: **0.11+** (important for new LSP API)

---

## 1. Install / Upgrade Neovim on WSL

The Ubuntu `apt` package often provides an older Neovim. For full LSP features and compatibility with `nvim-lspconfig`, install a recent Neovim from the official release.

### 1.1 Remove old Neovim (optional but recommended)

```bash
sudo apt remove neovim

```

### 1.2 Download Neovim (ARM, Linux)

From WSL, download the latest ARM64 tarball:

```bash
cd ~
wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz
tar xzf nvim-linux-arm64.tar.gz

```

This extracts a folder `nvim-linux-arm64`.

### 1.3 Move Neovim to a permanent location

```bash
sudo mv nvim-linux-arm64 /opt/nvim

```

### 1.4 Add Neovim to PATH

Create a symlink:

```bash
sudo ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim

```

### 1.5 Verify the version

```bash
nvim --version

```

Check that it reports **0.11.x** (or newer).

---

## 2. Install `clangd` for C/C++ LSP

Neovim talks LSP; `clangd` is the language server that provides C/C++ intelligence.

### 2.1 Install `clangd`

```bash
sudo apt update
sudo apt install clangd

```

### 2.2 Verify `clangd` is available

```bash
which clangd
clangd --version

```

You should see a valid path (`/usr/bin/clangd`) and a version string (e.g., `Ubuntu clangd version 18.x`).

---

## 3. Create Neovim Configuration Directory

Neovim reads configuration from `~/.config/nvim/init.lua` on Linux.

### 3.1 Create the config folder

```bash
mkdir -p ~/.config/nvim

```

### 3.2 Open the main config file

```bash
nvim ~/.config/nvim/init.lua

```

Paste the full configuration from the next section and save (`:wq`).

---

## 4. Final `init.lua` (Working Configuration)

This configuration does the following:

- Sets basic editor options and keymaps
- Bootstraps `lazy.nvim` as the plugin manager
- Installs and configures:
    - `lualine` (status line)
    - `nvim-tree` (file explorer)
    - `telescope` (fuzzy finder)
    - `nvim-treesitter` (syntax/indent)
    - `nvim-lspconfig` with **Neovim 0.11+ LSP API** using system `clangd`

> Paste everything below into ~/.config/nvim/init.lua:
> 

```lua
-- =========================
--  BASIC OPTIONS
-- =========================
vim.g.mapleader = " "

local o  = vim.o
local wo = vim.wo
local bo = vim.bo

-- Line numbers
wo.number = true
wo.relativenumber = true

-- Indentation
bo.expandtab   = true
bo.shiftwidth  = 4
bo.tabstop     = 4
bo.softtabstop = 4

-- Search
o.ignorecase = true
o.smartcase  = true
o.hlsearch   = true
o.incsearch  = true

-- UI
o.termguicolors = true
o.cursorline    = true
wo.signcolumn   = "yes"

-- Behaviour
o.updatetime = 300
o.timeoutlen = 500
o.clipboard  = "unnamedplus"

-- =========================
--  KEYMAP HELPERS
-- =========================
local map  = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Clear search highlight
map("n", "<leader>h", ":nohlsearch<CR>", opts)

-- Window navigation
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Save / quit
map("n", "<leader>w", ":w<CR>", opts)
map("n", "<leader>q", ":q<CR>", opts)
map("n", "<leader>x", ":x<CR>", opts)

-- =========================
--  LAZY.NVIM BOOTSTRAP
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =========================
--  PLUGINS
-- =========================
require("lazy").setup({
  -- Utility
  { "nvim-lua/plenary.nvim" },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled        = true,
          theme                = "auto",
          section_separators   = "",
          component_separators = "",
        },
      })
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({})
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    end,
  },

  -- Treesitter (better syntax / indent)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent    = { enable = true },
        ensure_installed = {
          "c", "cpp", "lua", "bash", "json", "yaml", "markdown",
        },
      })
    end,
  },

  -- LSP (using new vim.lsp.config API + system clangd)
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Capabilities (extend later for completion if needed)
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Configure clangd (merged with nvim-lspconfig defaults)
      vim.lsp.config("clangd", {
        capabilities = capabilities,
        -- cmd = { "clangd" }, -- optional override
      })

      -- Enable clangd for its supported filetypes
      vim.lsp.enable("clangd")

      -- Global LSP keymaps (apply to any attached server)
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "K",  vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
    end,
  },
})

```

---

## 5. First Run: Install Plugins with `lazy.nvim`

### 5.1 Start Neovim

```bash
nvim

```

On the first run with this `init.lua`, `lazy.nvim` will bootstrap itself.

### 5.2 Install plugins

Inside Neovim:

```
:Lazy sync

```

- Wait until all plugins are installed/updated.
- When finished, quit Neovim and reopen it:

```bash
nvim

```

---

## 6. Verify LSP (clangd) Is Working

### 6.1 Open a C++ project

From WSL:

```bash
cd ~/dev/testCPP/bst-operations-cpp   # example path
nvim main.cpp                         # or any .cpp file

```

### 6.2 Check filetype

Inside Neovim:

```
:set filetype?

```

It should print `filetype=cpp` (or `c`/`cpp` as appropriate).

### 6.3 Check LSP status

Run:

```
:LspInfo

```

You should see something like:

- `Active Clients: clangd`
- Root directory = your project directory
- Command = `{ "clangd" }`
- Attached buffers = at least 1

This confirms that Neovim has successfully attached `clangd` to your C++ buffer.

---

## 7. Quick Keymap Reference (Current Setup)

### Core Neovim

- Save: `<leader>w` (Space + w)
- Quit: `<leader>q`
- Save & quit: `<leader>x`
- Clear search highlight: `<leader>h`
- Window navigation: `Ctrl+h/j/k/l`

### Plugins

- File tree: `<leader>e` (toggle `nvim-tree`)
- Telescope file search: `<leader>ff`
- Telescope live grep: `<leader>fg`
- Telescope buffers: `<leader>fb`
- Telescope help tags: `<leader>fh`

### LSP (clangd)

In a C/C++ buffer with `clangd` attached:

- Go to definition: `gd`
- Hover info: `K`
- Go to implementation: `gi`
- Find references: `gr`
- Rename symbol: `<leader>rn`
- Code actions: `<leader>ca`
- Previous/next diagnostic: `[d` / `]d`

[Neovim - `init.lua` with Popular Plugins](Neovim%20-%20init%20lua%20with%20Popular%20Plugins%202c16ba4e52e480838084cb6f6ca0551b.md)