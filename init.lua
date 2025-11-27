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
      'buffer',
      'fittencode'
    },

    providers = {
      fittencode = {
        name = "fittencode",
        module = "fittencode.sources.blink"
      }
    }
  },

  snippets = {
    expand = function(snippet)
      vim.snippet.expand(snippet)
    end
  },
})

require('catppuccin').setup({
  transparent_background = true,
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

require('lualine').setup({
  options = {
    theme = "catppuccin",
    always_divide_middle = false,
    component_separators = { left = "", right = "" },
    section_seperators = { left = "", right = "" }
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { "filename" },
    lualine_x = { },
    lualine_y = { "encoding", "fileformat", "filetype", "progress" },
    lualine_z = { "location" }
  },
  winbar = {
    lualine_a = {
      "filename"
    },
    lualine_b = {
      { function() return " " end, color = 'Comment' }
    },
    lualine_x = {
      "lsp_status"
    }
  },
  inactive_winbar = {
    -- Always show winbar.
    lualine_b = { function() return " " end }
  }
})

vim.g.barbar_auto_setup = false
local barbar = require('barbar')
barbar.setup({
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

require('noice').setup({
  popmenu = {
    enabled = false
  },
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true
    }
  },
  presets = {
    bottom_search = false,
    command_palette = true,
    long_message_to_split = true,
    inc_rename = false,
    lsp_doc_border = true
  },
  routes = {
    { filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
    { filter = { event = "msg_show", kind = "" }, opts = { skip = true } }
  }
})

require('codecompanion').setup({
  log_level = "DEBUG"
})

require('fittencode').setup({
  completion_mode = 'source'
})

-- Shortcut keys setup.
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

vim.opt.list = true
vim.opt.listchars = { tab = ">-", trail = "-" }

vim.opt.hlsearch = true

vim.opt.scrolloff = 15
vim.opt.sidescrolloff = 10
vim.opt.startofline = false

vim.opt.number = true
vim.wo.wrap = false

-- These configurations disables auto blank-to-TAB convertion.
vim.opt.expandtab = true
vim.opt.smarttab = false
vim.opt.smartindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-l>", "<Right>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-k>", "<Up>")

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

vim.keymap.set("n", "<A-<>", "<CMD>BufferMovePrevious<CR>", { desc = "[Buffer] Move buffer left" })
vim.keymap.set("n", "<A->>", "<CMD>BufferMoveNext<CR>", { desc = "[Buffer] Move buffer right" })
vim.keymap.set("n", "<A-1>", "<CMD>BufferGoto 1<CR>", { desc = "[Buffer] Go to buffer 1" })
vim.keymap.set("n", "<A-2>", "<CMD>BufferGoto 2<CR>", { desc = "[Buffer] Go to buffer 2" })
vim.keymap.set("n", "<A-3>", "<CMD>BufferGoto 3<CR>", { desc = "[Buffer] Go to buffer 3" })
vim.keymap.set("n", "<A-4>", "<CMD>BufferGoto 4<CR>", { desc = "[Buffer] Go to buffer 4" })
vim.keymap.set("n", "<A-5>", "<CMD>BufferGoto 5<CR>", { desc = "[Buffer] Go to buffer 5" })
vim.keymap.set("n", "<A-6>", "<CMD>BufferGoto 6<CR>", { desc = "[Buffer] Go to buffer 6" })
vim.keymap.set("n", "<A-7>", "<CMD>BufferGoto 7<CR>", { desc = "[Buffer] Go to buffer 7" })
vim.keymap.set("n", "<A-8>", "<CMD>BufferGoto 8<CR>", { desc = "[Buffer] Go to buffer 8" })
vim.keymap.set("n", "<A-9>", "<CMD>BufferGoto 9<CR>", { desc = "[Buffer] Go to buffer 9" })
vim.keymap.set("n", "<A-h>", "<CMD>BufferPrevious<CR>", { desc = "[Buffer] Previous buffer" })
vim.keymap.set("n", "<A-l>", "<CMD>BufferNext<CR>", { desc = "[Buffer] Next buffer" })
vim.keymap.set("n", "<A-w>", "<CMD>BufferClose<CR>", { desc = "[Buffer] Go to buffer 1" })

vim.keymap.set("n", "<leader>e", "<CMD>NvimTreeToggle<CR>", { desc = "[NvimTree] Toggle NvimTree" })

vim.keymap.set({ "n", "v" }, "<leader>cca", "<CMD>CodeCompanionActions<CR>", { desc = "CodeCompanion action" })
vim.keymap.set({ "n", "v" }, "<leader>cci", "<CMD>CodeCompanion<CR>", { desc = "CodeCompanion inline" })
vim.keymap.set({ "n", "v" }, "<leader>ccc", "<CMD>CodeCompanionChat Toggle<CR>", { desc = "CodeCompanion chat" })
vim.keymap.set("v", "<leader>ccp", "<CMD>CodeCompanionChat Add<CR>", { desc = "CodeCompanion chat" })

