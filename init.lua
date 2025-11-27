
vim.opt.list = true
vim.opt.listchars = { tab = ">-", trail = "-" }

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K",  vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
  --vim.keymap.set("n", "<leader>vd", vim.lsp.buf.open_float, opts)
  --vim.keymap.set("n", "[d", vim.lsp.buf.goto_next, opts)
  --vim.keymap.set("n", "]d", vim.lsp.buf.goto_prev, opts)
  vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
  vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
end)

vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-l>", "<Right>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-k>", "<Up>")

vim.keymap.set("i", "jk", "<Esc>")

vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")

vim.keymap.set({ "n", "x" }, "<S-H>", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "x" }, "<S-L>", "$", { desc = "End of line" })
vim.keymap.set("n", "y<S-H>", "y^", { desc = "Yank from start of line" })
vim.keymap.set("n", "y<S-L>", "y$", { desc = "Yank to end of line" })

vim.keymap.set({ "n", "x" }, "Q", "<CMD>:qa<CR>")
vim.keymap.set({ "n", "x" }, "qq", "<CMD>:q<CR>")

vim.keymap.set("n", "<A-z>", "<CMD>set wrap!<CR>", { desc = "Toggle line wrap" })

require('lsp-zero').extend_lspconfig({
  sign_text = true,
  lsp_skip_setup = { },
})

---@diagnostic disable-next-line: missing-parameter
require('lspconfig').lua_ls.setup({
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = { library = vim.api.nvim_get_runtime_file("", true) },
      telemetry = { enable = false },
    },
  },
})

require('lspconfig').rust_analyzer.setup{}
require('lspconfig').pyright.setup{}
require('lspconfig').ts_ls.setup{}
require('lspconfig').nil_ls.setup{}

local cmp = require('cmp')
local cmp_action = require('lsp-zero').cmp_action()

cmp.setup({
  sources = {
    {name = 'nvim_lsp'},
    {name = 'luasnip'},
    {name = 'buffer'},
    {name = 'path'},
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({select = true}),
    ['<Tab>'] = cmp_action.luasnip_supertab(),
    ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
  }),
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
})

local blink = require('blink.cmp')

blink.setup({
  appearance = {
    nerd_font_variant = "normal",
    use_nvim_cmp_as_default = false
  },

  keymap = {
    preset = 'default',

    -- TODO
  },

  sources = {
    default = {
      'lsp',
      'path',
      'snippets',
      'buffer'
    }
  },

  snippets = {
    expand = function(snippet)
      vim.snippet.expand(snippet)
    end
  },
})

require('catppuccin').setup({
  --transparent_background = true,
  custom_highlights = function(colors)
    return {
      LineNr = { fg = colors.surface2 },
      Visual = { bg = colors.overlay0 },
      Search = { bg = colors.surface2 },
      IncSearch = { bg = colors.lavender },
      CurSearch = { bg = colors.lavender },
      MarchParen = { bg = colors.lavender, fg = colors.base, bold = true }
    }
  end,
  integrations = {
    barbar = true,
    blink_cmp = true,
    gitsigns = true,
    noice = true,
    notify = true,
    nvimtree = true,
    rainbow_delimiters = true
  }
})

require('lualine').setup()

vim.g.barbar_auto_setup = false
require('barbar').setup({
  animation = true,
  auto_hide = false,
  tabpages = true,
  clickable = true
})

require('nvim-tree').setup()

vim.g.rainbow_delimiters = {
  strategy = {
    [''] = 'rainbow-delimiters.strategy.global',
    vim = 'rainbow-delimiters.strategy.local'
  },
  query = {
    [''] = 'rainbow-delimiters',
    lua = 'rainbow-blocks'
  },
  priority = {
    [''] = 110,
    lua = 210
  },
  highlight = {
    'RainbowDelimiterRed',
    'RainbowDelimiterYellow',
    'RainbowDelimiterBlue',
    'RainbowDelimiterOrange',
    'RainbowDelimiterGreen',
    'RainbowDelimiterViolet',
    'RainbowDelimiterCyan'
  }
};

require('noice').setup()

