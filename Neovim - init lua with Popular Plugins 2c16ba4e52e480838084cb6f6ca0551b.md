# Neovim - init.lua with Popular Plugins

**`init.lua`**:

- Neovim 0.11+
- lazy.nvim
- Theme, statusline, file tree, Telescope, Treesitter
- Git signs
- Snippets + completion (nvim-cmp)
- **LSP for C++ (`clangd`) and Python (`pyright`) only**
- Java: syntax highlighting via Treesitter (no LSP complexity)

Paste this into `~/.config/nvim/init.lua`:

```lua
-----------------------------------------------------------
-- BASIC OPTIONS
-----------------------------------------------------------
vim.g.mapleader = " "

local o  = vim.o
local wo = vim.wo

-- Line numbers
wo.number = true
wo.relativenumber = true

-- Indentation
o.expandtab   = true
o.shiftwidth  = 4
o.tabstop     = 4
o.softtabstop = 4

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

-----------------------------------------------------------
-- KEYMAPS
-----------------------------------------------------------
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

-- clang-format on current file (needs: sudo apt install clang-format)
map("n", "<leader>f", ":!clang-format -i %<CR>", opts)

-- panic quit
map("n", "<leader>Q", ":qa!<CR>", opts)

-----------------------------------------------------------
-- LAZY.NVIM BOOTSTRAP
-----------------------------------------------------------
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

-----------------------------------------------------------
-- PLUGINS
-----------------------------------------------------------
require("lazy").setup({

  -------------------------------------------------------
  -- Utility
  -------------------------------------------------------
  { "nvim-lua/plenary.nvim" },

  -------------------------------------------------------
  -- Colorscheme: tokyonight
  -------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    config = function()
      vim.cmd("colorscheme tokyonight")
    end,
  },

  -------------------------------------------------------
  -- Status line: lualine
  -------------------------------------------------------
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

  -------------------------------------------------------
  -- File explorer: nvim-tree
  -------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({})
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })
    end,
  },

  -------------------------------------------------------
  -- Fuzzy finder: telescope
  -------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
      vim.keymap.set("n", "<leader>gd", builtin.lsp_definitions, {})
      vim.keymap.set("n", "<leader>gr", builtin.lsp_references, {})
      vim.keymap.set("n", "<leader>gi", builtin.lsp_implementations, {})
      vim.keymap.set("n", "<leader>gs", builtin.lsp_document_symbols, {})
    end,
  },

  -------------------------------------------------------
  -- Treesitter: syntax + indent
  -------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent    = { enable = true },
        ensure_installed = {
          "c",
          "cpp",
          "lua",
          "bash",
          "json",
          "yaml",
          "markdown",
          "python",
          "java",
        },
      })
    end,
  },

  -------------------------------------------------------
  -- Git signs in gutter
  -------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -------------------------------------------------------
  -- Snippets: LuaSnip + friendly-snippets
  -------------------------------------------------------
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()
      luasnip.config.set_config({
        history = true,
        updateevents = "TextChanged,TextChangedI",
      })
    end,
  },

  -------------------------------------------------------
  -- Completion: nvim-cmp
  -------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"]   = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"]    = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "path" },
          { name = "buffer" },
        }),
      })
    end,
  },

  -------------------------------------------------------
  -- LSP: clangd (C/C++) + pyright (Python)
  -- uses Neovim 0.11+ vim.lsp.config API
  -------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Base capabilities (extended by cmp if present)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok_cmp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      -- C/C++: clangd
      vim.lsp.config("clangd", {
        capabilities = capabilities,
      })
      vim.lsp.enable("clangd")

      -- Python: pyright
      vim.lsp.config("pyright", {
        capabilities = capabilities,
      })
      vim.lsp.enable("pyright")

      -- Global LSP keymaps (for any attached server)
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

After saving:

```bash
sudo apt install clangd clang-format pyright ripgrep git   # pyright via apt if available; else npm -g pyright
nvim
```

In Neovim:

```
:Lazy sync
```

Then:

- C++ file → `:LspInfo` should show `clangd`
- Python file → `:LspInfo` should show `pyright`
- Java file → nice syntax (Treesitter), but no LSP, by design