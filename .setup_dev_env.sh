#!/usr/bin/env bash
set -e

# ==========================================================
# Safety checks
# ==========================================================
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run this as root. It uses sudo internally."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required."
  exit 1
fi

if ! command -v apt >/dev/null 2>&1; then
  echo "This script assumes Ubuntu/Debian (apt)."
  exit 1
fi

# ==========================================================
# Detect architecture → Neovim asset
# ==========================================================
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64) NVIM_TARBALL="nvim-linux-arm64.tar.gz" ;;
  x86_64)  NVIM_TARBALL="nvim-linux-x86_64.tar.gz" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# ==========================================================
# 1) Install zsh + Oh My Zsh
# ==========================================================
install_zsh_and_ohmyzsh() {
  echo "==> Installing zsh + basic CLI tools..."
  sudo apt update
  sudo apt install -y zsh git curl wget fzf

  echo "==> Installing Oh My Zsh..."
  export RUNZSH=no
  export CHSH=no
  export KEEP_ZSHRC=yes

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh already installed, skipping."
  fi

  # Ensure we at least have a .zshrc
  if [[ ! -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
  fi
}

# ==========================================================
# 2) Java 17, pyenv + latest Python, nvm + Node/npm
#    (also installs build deps, ripgrep, clangd, docker, etc.)
# ==========================================================
install_dev_tools() {
  echo "==> Installing build dependencies and dev tools..."

  sudo apt update
  sudo apt install -y \
    build-essential \
    ripgrep \
    clangd clang-format \
    docker.io \
    ca-certificates \
    gnupg \
    pkg-config \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev

  echo "==> Installing Java 17..."
  sudo apt install -y software-properties-common
  sudo add-apt-repository ppa:openjdk-r/ppa -y || true
  sudo apt update
  sudo apt install -y openjdk-17-jdk
  java -version || true
  javac -version || true

  echo "==> Installing pyenv..."
  if [[ ! -d "$HOME/.pyenv" ]]; then
    curl https://pyenv.run | bash
  else
    echo "pyenv already present, skipping install."
  fi

  # Configure pyenv for login shells
  for f in "$HOME/.profile" "$HOME/.zprofile"; do
    if [[ -f "$f" ]] && grep -q 'PYENV_ROOT' "$f"; then
      continue
    fi
    cat >> "$f" <<'EOF'

# pyenv setup (added by setup_dev_env.sh)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
EOF
  done

  # For interactive zsh
  if [[ -f "$HOME/.zshrc" ]] && ! grep -q 'pyenv init -' "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" <<'EOF'

# pyenv init for interactive zsh (added by setup_dev_env.sh)
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
EOF
  fi

  # Use pyenv in this script
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"

  echo "==> Installing latest Python 3 via pyenv..."
  latest_py=$(pyenv install --list | sed 's/ //g' \
               | grep -E '^3\.[0-9]+\.[0-9]+$' | tail -1)
  pyenv install -s "$latest_py"
  pyenv global "$latest_py"
  python3 --version || python --version || true

  echo "==> Installing nvm + latest Node/npm..."
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -d "$NVM_DIR" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
  # load nvm now
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

  nvm install node
  nvm alias default node
  node -v
  npm -v
  npx -v

  echo "==> Installing pyright (for Neovim Python LSP)..."
  if command -v npm >/dev/null 2>&1; then
    npm install -g pyright || echo "npm pyright install failed, install manually later."
  else
    echo "npm not found, pyright not installed."
  fi
}

# ==========================================================
# 3) Oh My Zsh plugins + theme agnoster
# ==========================================================
install_ohmyzsh_plugins_and_theme() {
  echo "==> Installing Oh My Zsh plugins (autosuggestions + syntax highlighting)..."

  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true

  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true

  # Ensure plugins list; remove kubectl, set theme to agnoster
  if grep -q "^plugins=" "$HOME/.zshrc"; then
    # Replace the existing plugins= line
    sed -i 's/^plugins=(.*$/plugins=(git z extract pip pyenv docker fzf colored-man-pages history-substring-search zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc" || true
  else
    cat >> "$HOME/.zshrc" <<'EOF'

plugins=(
  git
  z
  extract
  pip
  pyenv
  docker
  fzf
  colored-man-pages
  history-substring-search
  zsh-autosuggestions
  zsh-syntax-highlighting
)
EOF
  fi

  # Set theme to agnoster
  if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$HOME/.zshrc"
  else
    echo 'ZSH_THEME="agnoster"' >> "$HOME/.zshrc"
  fi

  echo
  echo "NOTE: To make zsh your default shell:"
  echo "  chsh -s \"$(which zsh)\""
}

# ==========================================================
# 4) Update ~/.vimrc
# ==========================================================
create_vimrc() {
  echo "==> Writing ~/.vimrc..."
  cat > "$HOME/.vimrc" <<'EOF'
" Basic Vim settings
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set cursorline
set clipboard=unnamedplus
set hlsearch
set incsearch
set ignorecase
set smartcase
syntax on
set termguicolors
filetype plugin indent on

" Simple mappings
nnoremap <Space> :noh<CR>
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a
EOF
}

# ==========================================================
# 5a) Install Neovim (from GitHub release)
# ==========================================================
install_neovim() {
  echo "==> Installing Neovim (latest release)..."
  cd "$HOME"

  if dpkg -l | grep -q "^ii\s\+neovim\s"; then
    sudo apt remove -y neovim
  fi

  echo "== Querying GitHub API for latest Neovim asset =="
  LATEST_URL=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
    | grep "browser_download_url" \
    | grep "${NVIM_TARBALL}" \
    | cut -d '"' -f 4)

  if [[ -z "$LATEST_URL" ]]; then
    echo "Could not find asset ${NVIM_TARBALL}"
    exit 1
  fi

  echo "Downloading: $LATEST_URL"
  wget -O "${NVIM_TARBALL}" "$LATEST_URL"
  tar xzf "${NVIM_TARBALL}"
  rm -f "${NVIM_TARBALL}"

  sudo rm -rf /opt/nvim || true
  sudo mv nvim-linux-* /opt/nvim

  sudo rm -f /usr/local/bin/nvim || true
  sudo ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim

  echo "Neovim version: $(nvim --version | head -n 1)"
}

# ==========================================================
# 5b) Neovim init.lua with your plugins
# ==========================================================
setup_neovim_config() {
  echo "==> Writing Neovim config to ~/.config/nvim/init.lua..."
  mkdir -p "$HOME/.config/nvim"

  cat > "$HOME/.config/nvim/init.lua" <<'EOF'
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
EOF
}

# ==========================================================
# MAIN
# ==========================================================
install_zsh_and_ohmyzsh
install_dev_tools
install_ohmyzsh_plugins_and_theme
create_vimrc
install_neovim
setup_neovim_config

echo
echo "==================================================="
echo "Setup complete."
echo "Open a NEW shell (so pyenv/nvm/zsh config loads), then:"
echo "  nvim  -> :Lazy sync  (install plugins)"
echo "==================================================="
