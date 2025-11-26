vim.wo.cursorline = true
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

