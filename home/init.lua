-- Make the background transparent.
vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'none' })

require('lsp-zero').extend_lspconfig({
    sign_text = true,
    lsp_skip_setup = { },
})

---@diagnostic disable-next-line: missing-parameter
vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
        },
    },
})
vim.lsp.config('rust_analyzer', {})
vim.lsp.config('pyright', {})
vim.lsp.config('ts_ls', {})
vim.lsp.config('nil_ls', {})

vim.lsp.enable('lua_ls')
vim.lsp.enable('rust_analyzer')
vim.lsp.enable('pyright')
vim.lsp.enable('ts_ls')
vim.lsp.enable('nil_ls')
vim.lsp.enable('sqls')
vim.lsp.enable('gopls')
vim.lsp.enable('hls')
vim.lsp.enable('verible')

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
        default = function()
            local success, node = pcall(vim.treesitter.get_node)
            if success and node and vim.tbl_contains({ "comment", "line_comment", "block_comment" },
                node:type()) then
                return { "buffer" }
            else
                return { "lazydev", "copilot", "lsp", "path", "snippets", "buffer" }
            end
        end,

        providers = {
            lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                -- make lazydev completions top priority (see `:h blink.cmp`)
                score_offset = 95
            },
            copilot = {
                name = "copilot",
                module = "blink-copilot",
                score_offset = 100,
                async = true,
                opts = {
                    kind_icon = "",
                    kind_hl = "DevIconCopilot",
                }
            },
            path = {
                score_offset = 95,
                opts = {
                    get_cwd = function(_)
                        return vim.fn.getcwd()
                    end,
                }
            },
            buffer = {
                score_offset = 20,
            },
            lsp = {
                -- Default
                -- Filter text items from the LSP provider, since we have the buffer provider for that
                transform_items = function(_, items)
                    return vim.tbl_filter(function(item)
                        return item.kind ~= require("blink.cmp.types").CompletionItemKind.Text
                    end, items)
                end,
                score_offset = 60,
                fallbacks = { "buffer" }
            },
            -- Hide snippets after trigger character
            -- Trigger characters are defined by the sources. For example, for Lua, the trigger characters are ., ", '.
            snippets = {
                score_offset = 70,
                should_show_items = function(ctx)
                    return ctx.trigger.initial_kind ~= "trigger_character"
                end,
                fallbacks = { "buffer" }
            },
            cmdline = {
                min_keyword_length = 2,
                -- Ignores cmdline completions when executing shell commands
                enabled = function()
                    return vim.fn.getcmdtype() ~= ":" or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
                end
            }
        }
    },

    snippets = {
        expand = function(snippet)
            vim.snippet.expand(snippet)
        end
    }
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
vim.cmd("colorscheme catppuccin")

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
    log_level = "DEBUG",
    display = {
        diff = {
            enabled = true,
            provider = "mini_diff"
        }
    },
    strategies = {
        chat = { adapter = "copilot" },
        inline = { adapter = "copilot" }
    },
    opts = {
        language = "English"
    }
});
(function()
    local progress = require("fidget.progress")

    local M = {}

    function M:init()
        local group = vim.api.nvim_create_augroup("CodeCompanionFidgetHooks", {})

        vim.api.nvim_create_autocmd({ "User" }, {
            pattern = "CodeCompanionRequestStarted",
            group = group,
            callback = function(request)
                local handle = M:create_progress_handle(request)
                M:store_progress_handle(request.data.id, handle)
            end,
        })

        vim.api.nvim_create_autocmd({ "User" }, {
            pattern = "CodeCompanionRequestFinished",
            group = group,
            callback = function(request)
                local handle = M:pop_progress_handle(request.data.id)
                if handle then
                    M:report_exit_status(handle, request)
                    handle:finish()
                end
            end,
        })
    end

    M.handles = {}

    function M:store_progress_handle(id, handle)
        M.handles[id] = handle
    end

    function M:pop_progress_handle(id)
        local handle = M.handles[id]
        M.handles[id] = nil
        return handle
    end

    function M:create_progress_handle(request)
        return progress.handle.create({
            title = " Requesting assistance (" .. request.data.strategy .. ")",
            message = "In progress...",
            lsp_client = {
                name = M:llm_role_title(request.data.adapter),
            },
        })
    end

    function M:llm_role_title(adapter)
        local parts = {}
        table.insert(parts, adapter.formatted_name)
        if adapter.model and adapter.model ~= "" then
            table.insert(parts, "(" .. adapter.model .. ")")
        end
        return table.concat(parts, " ")
    end

    function M:report_exit_status(handle, request)
        if request.data.status == "success" then
            handle.message = "Completed"
        elseif request.data.status == "error" then
            handle.message = " Error"
        else
            handle.message = "󰜺 Cancelled"
        end
    end

    return M
end)():init()

require('lazydev').setup({
    library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } }
    }
})

require('which-key').setup({
    preset = "helix",
    win = {
        title = false,
        width = 0.5
    },
    spec = {
        { "<leader>cc", group = "<CodeCompanion>" },
        { "<leader>s", group = "<Snacks>" },
        { "<leader>t", group = "<Snacks> Toggle" }
    },
    expand = function(node)
        return not node.desc
    end
})

local snacks = require('snacks')
snacks.setup({
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = {
        enabled = true,
        animate = {
            enabled = false
        },
        indent = {
            only_scope = true
        },
        scope = {
            enabled = true, -- enable highlighting of the current scope
            underline = true, -- underline the start of the current scope
        },
        chunk = {
            -- when enabled, scopes will be rendered as chunks,
            -- except for the top-level scope, which will be rendered as a scope.
            enabled = true
        }
    },
    input = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },

    image = {
        enabled = true,
        doc = { inline = false, float = false, max_width = 80, max_height = 40 },
        math = { latex = { font_size = "small" } }
    },

    lazygit = {
        enabled = true,
        configure = false
    },

    notifier = {
        enabled = true,
        style = "notification"
    },

    picker = {
        enabled = true,
        previewers = {
            diff = {
                builtin = false,
                cmd = { "delta" }
            },
            git = {
                builtin = false,
                args = {}
            }
        },
        sources = {
            spelling = {
                layout = { preset = "select" }
            }
        },
        win = {
            input = {
                keys = {
                    ["<Tab>"] = { "select_and_prev", mode = { "i", "n" } },
                    ["<S-Tab>"] = { "select_and_next", mode = { "i", "n" } },
                    ["<A-Up>"] = { "history_back", mode = { "i", "n" } },
                    ["<A-Down>"] = { "history_forward", mode = { "i", "n" } },
                    ["<A-j>"] = { "list_down", mode = { "i", "n" } },
                    ["<A-k>"] = { "list_up", mode = { "i", "n" } },
                    ["<C-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
                    ["<C-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
                    ["<A-u>"] = { "list_scroll_up", mode = { "i", "n" } },
                    ["<A-d>"] = { "list_scroll_down", mode = { "i", "n" } },
                    ["<c-j>"] = {},
                    ["<c-k>"] = {}
                }
            }
        },
        layout = {
            preset = "telescope"
        }
    }
})
vim.api.nvim_create_autocmd("VimEnter", {
    pattern = "",
    callback = function()
        -- Setup some globals for debugging.
        _G.dd = function(...)
            snacks.debug.inspect(...)
        end
        _G.bt = function()
            snacks.debug.backtrace()
        end
        vim.print = _G.dd

        vim.g.snacks_animate = false
        snacks.toggle.new({
            id = "Animation",
            name = "Animation",
            get = function()
                return snacks.animate.enabled()
            end,
            set = function(state)
                vim.g.snacks_animate = state
            end
        }):map("<leader>ta")

        -- Create some toggle mappings for snacks.
        snacks.toggle.dim():map("<leader>tD")

        snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>ts")
        snacks.toggle.option("wrap", { name = "Wrap" }):map("<ledaer>tw")
        snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>tL")
        snacks.toggle.diagnostics():map("<leader>td")
        snacks.toggle.line_number():map("<leader>tl")
        snacks.toggle.option("conceallevel", { off = 0, om = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>tc")
        snacks.toggle.treesitter():map("<leader>tT")
        snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>tb")
        snacks.toggle.inlay_hints():map("<leader>th")
        snacks.toggle.indent():map("<leader>tg")
        snacks.toggle.dim():map("<leader>tD")
    end
})

require('nvim-autopairs').setup({
    ignored_next_char = "[%w%.]" -- will ignore alphanumeric and `.` symbol
})

require('trim').setup({
    trim_last_line = false
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function()
        require("lint").try_lint()
        require("lint").try_lint("codespell")
    end
})

require('scrollbar').setup({
    handelers = {
        gitsigns = true, -- Requires gitsigns
        search = true, -- Requires hlslens
    },
    marks = {
        Search = {
            color = "#CBA6F7",
        },
        GitAdd = { text = "┃" },
        GitChange = { text = "┃" },
        GitDelete = { text = "_" }
    }
})

require('hlslens').setup({
    nearest_only = true
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

vim.cmd([[
  if has("persistent_undo")
  let target_path = expand("~/.undodir")

  " create the directory and any parent directories if the location does not exist.
  if !isdirectory(target_path)
  call mkdir(target_path, "p", 0700)
  endif

  let &undodir = target_path
  set undofile
  endif
]])

require('Comment').setup()

require('smartyank').setup({
    highlight = {
        timeout = 500 -- timeout for cleaning the highlight
    },
    clipboard = {
        enable = true
    },
    osc52 = {
        silent = true -- disable the "n chars copied" echo
    }
})

require('flash').setup({
    label = {
        rainbow = {
            enabled = true,
            shade = 1
        }
    },
    modes = {
        char = {
            enabled = false
        }
    }
})

require('todo-comments').setup({
    highlight = {
        keyword = "wide_bg",
        before = "bg",
        after = "fg"
    }
})

-- local multicursor = require('multicursor-nvim')
-- multicursor.setup()
-- multicursor.addKeymapLayer(function(layerSet)
--   layerSet("n", "<esc>", function()
--     multicursor.clearCursors()
--   end)
-- end)

require('trouble').setup({})

require('gitsigns').setup({})

require('gitsigns').setup({
    signcolumn = false,
    numhl = true,
    -- word_diff = true,
    current_line_blame = true,
    attach_to_untracked = true,
    preview_config = {
        border = "rounded"
    },
    on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        -- stylua: ignore
        map("n", "]h", function() if vim.wo.diff then vim.cmd.normal({ "]h", bang = true }) else gitsigns.nav_hunk("next") end end, { desc = "[Git] Next hunk" })
        -- stylua: ignore
        map("n", "]H", function() if vim.wo.diff then vim.cmd.normal({ "]H", bang = true }) else gitsigns.nav_hunk("last") end end, { desc = "[Git] Last hunk" })
        -- stylua: ignore
        map("n", "[h", function() if vim.wo.diff then vim.cmd.normal({ "[h", bang = true }) else gitsigns.nav_hunk("prev") end end, { desc = "[Git] Prev hunk" })
        -- stylua: ignore
        map("n", "[H", function() if vim.wo.diff then vim.cmd.normal({ "[H", bang = true }) else gitsigns.nav_hunk("first") end end, { desc = "[Git] First hunk" })

        -- Actions
        map("n", "<leader>ggs", gitsigns.stage_hunk, { desc = "[Git] Stage hunk" })
        -- stylua: ignore
        map("v", "<leader>ggs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "[Git] Stage hunk (Visual)" })

        map("n", "<leader>ggr", gitsigns.reset_hunk, { desc = "[Git] Reset hunk" })
        -- stylua: ignore
        map("v", "<leader>ggr", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "[Git] Reset hunk (Visual)" })

        map("n", "<leader>ggS", gitsigns.stage_buffer, { desc = "[Git] Stage buffer" })
        map("n", "<leader>ggR", gitsigns.reset_buffer, { desc = "[Git] Reset buffer" })

        map("n", "<leader>ggp", gitsigns.preview_hunk, { desc = "[Git] Preview hunk" })
        map("n", "<leader>ggP", gitsigns.preview_hunk_inline, { desc = "[Git] Preview hunk inline" })

        -- map("n", "<leader>ggb", function() gitsigns.blame_line({ full = true }) end, { desc = "[Git] Blame line" })

        -- stylua: ignore
        -- map("n", "<leader>ggd", gitsigns.diffthis, { desc = "[Git] diff" })
        -- stylua: ignore
        -- map("n", "<leader>ggD", function() gitsigns.diffthis("~") end, { desc = "[Git] diff (ALL)" })

        -- stylua: ignore
        map("n", "<leader>ggQ", function() gitsigns.setqflist("all") end, { desc = "[Git] Show diffs (ALL) in qflist" })
        -- stylua: ignore
        map("n", "<leader>ggq", gitsigns.setqflist, { desc = "[Git] Show diffs in qflist" })

        -- Text object
        map({ "o", "x" }, "ih", gitsigns.select_hunk, { desc = "[Git] Current hunk" })

        -- Toggles
        require("snacks")
            .toggle({
                name = "line blame",
                get = function()
                    return require("gitsigns.config").config.current_line_blame
                end,
                set = function(enabled)
                    require("gitsigns").toggle_current_line_blame(enabled)
                end
            })
            :map("<leader>tgb")
        require("snacks")
            .toggle({
                name = "word diff",
                get = function()
                    return require("gitsigns.config").config.word_diff
                end,
                set = function(enabled)
                    require("gitsigns").toggle_word_diff(enabled)
                end
            })
            :map("<leader>tgw")
    end
})

require('colorizer').setup()

require('ufo').setup({
    provider_selector = function(_, _, _)
        return { "treesitter", "indent" }
    end,

    open_fold_hl_timeout = 0,
    fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (" 󰁂 %d "):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if targetWidth > curWidth + chunkWidth then
                table.insert(newVirtText, chunk)
            else
                chunkText = truncate(chunkText, targetWidth - curWidth)
                local hlGroup = chunk[2]
                table.insert(newVirtText, { chunkText, hlGroup })
                chunkWidth = vim.fn.strdisplaywidth(chunkText)
                -- str width returned from truncate() may less than 2nd argument, need padding
                if curWidth + chunkWidth < targetWidth then
                    suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
                end
                break
            end
            curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, "MoreMsg" })
        return newVirtText
    end
})
vim.o.foldenable = true
vim.o.foldcolumn = "0" -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.opt.fillchars = {
    fold = " ",
    foldopen = "▾",
    foldsep = "│",
    foldclose = "▸",
}
(function()
    -- Ensure our ufo foldlevel is set for the buffer
    vim.api.nvim_create_autocmd("BufReadPre", {
        callback = function()
            vim.b.ufo_foldlevel = 0
        end,
    })

    ---@param num integer Set the fold level to this number
    local set_buf_foldlevel = function(num)
        vim.b.ufo_foldlevel = num
        require("ufo").closeFoldsWith(num)
    end

    ---@param num integer The amount to change the UFO fold level by
    local change_buf_foldlevel_by = function(num)
        local foldlevel = vim.b.ufo_foldlevel or 0
        -- Ensure the foldlevel can't be set negatively
        if foldlevel + num >= 0 then
            foldlevel = foldlevel + num
        else
            foldlevel = 0
        end
        set_buf_foldlevel(foldlevel)
    end

    -- Keymaps
    vim.keymap.set("n", "K", function()
        local winid = require("ufo").peekFoldedLinesUnderCursor()
        if not winid then
            vim.lsp.buf.hover()
        end
    end)

    -- stylua: ignore
    vim.keymap.set("n", "zM", function() set_buf_foldlevel(0) end, { desc = "[UFO] Close all folds" })
    vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "[UFO] Open all folds" })

    vim.keymap.set("n", "zm", function()
        local count = vim.v.count
        if count == 0 then
            count = 1
        end
        change_buf_foldlevel_by(-count)
    end, { desc = "[UFO] Fold More" })
    vim.keymap.set("n", "zr", function()
        local count = vim.v.count
        if count == 0 then
            count = 1
        end
        change_buf_foldlevel_by(count)
    end, { desc = "[UFO] Fold Less" })

    -- 99% sure `zS` isn't mapped by default
    vim.keymap.set("n", "zS", function()
        if vim.v.count == 0 then
            vim.notify("No foldlevel given to set!", vim.log.levels.WARN)
        else
            set_buf_foldlevel(vim.v.count)
        end
    end, { desc = "[UFO] Set foldlevel" })

    -- Delete some predefined keymaps as they are not compatible with nvim-ufo
    vim.keymap.set("n", "zE", "<NOP>", { desc = "Disabled" })
    vim.keymap.set("n", "zx", "<NOP>", { desc = "Disabled" })
    vim.keymap.set("n", "zX", "<NOP>", { desc = "Disabled" })
end)()

require('copilot').setup({
    suggestion = { enabled = false },
    panel = { enabled = false },
    filetypes = {
        markdown = true,
        help = true
    }
})

require('mini.diff').setup({})

-- 基本 LSP 设置（如果你没有，可添加）
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
local function default_on_attach(client, bufnr)
    -- 你的 on_attach 函数，如映射等
end

-- Metals 配置
local metals_config = require('metals').bare_config()
metals_config.capabilities = capabilities
metals_config.on_attach = default_on_attach

-- 关键：设置 metalsBinaryPath 到 Nix 路径，避免安装
metals_config.settings = {
    metalsBinaryPath = "{{METALS_BINARY_PATH}}/bin/metals",  -- Nix 插值，确保绝对路径
    useGlobalExecutable = true,  -- 可选：如果想依赖 PATH 而非具体路径
    -- 其他设置，如 serverProperties
    serverProperties = { "-Xmx2G", "-XX:+UseZGC" },  -- 示例 JVM opts，像 flake 中
    showImplicitArguments = true,
    -- ... 根据需要添加
}

-- 诊断处理（可选，但推荐）
metals_config.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = { prefix = '' } }
)
vim.opt_global.shortmess:remove("F")

-- Autocmd 来附加 Metals
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "scala", "sbt", "java" },
  callback = function()
    require('metals').initialize_or_attach(metals_config)
  end,
  group = vim.api.nvim_create_augroup("nvim-metals", { clear = true }),
})

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
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

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

vim.keymap.set({ "n", "x", "o" }, "<S-H>", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "x", "o" }, "<S-L>", "$", { desc = "End of line" })

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

vim.keymap.set("n", "<leader>e", "<CMD>NvimTreeToggle<CR>", { desc = "[NvimTree] Toggle NvimTree" })

vim.keymap.set({ "n", "v" }, "<leader>cca", "<CMD>CodeCompanionActions<CR>", { desc = "CodeCompanion action" })
vim.keymap.set({ "n", "v" }, "<leader>cci", "<CMD>CodeCompanion<CR>", { desc = "CodeCompanion inline" })
vim.keymap.set({ "n", "v" }, "<leader>ccc", "<CMD>CodeCompanionChat Toggle<CR>", { desc = "CodeCompanion chat" })
vim.keymap.set("v", "<leader>ccp", "<CMD>CodeCompanionChat Add<CR>", { desc = "CodeCompanion chat" })

vim.keymap.set("n", "<A-w>", function() snacks.bufdelete() end, { desc = "[Snacks] Delete buffer" })
vim.keymap.set("n", "<leader>si", function() snacks.image.hover() end, { desc = "[Snacks] Display image" })

vim.keymap.set("n", "<leader>sn", function() snacks.picker.notifications() end, { desc = "[Snacks] Notifications" })
vim.keymap.set("n", "<leader>n", function() snacks.notifier.show_history() end, { desc = "[Snacks] Notification history" })
vim.keymap.set("n", "<leader>un", function() snacks.notifier.hide() end, { desc = "[Snacks] Dismiss all notifications" })

vim.keymap.set("n", "<leader><space>", function() snacks.picker.smart() end, { desc = "[Snacks] Smart find files" })
vim.keymap.set("n", "<leader>,", function() snacks.picker.buffers() end, { desc = "[Snacks] Buffers" })

vim.keymap.set("n", "<leader>sb", function() snacks.picker.buffers() end, { desc = "[Snacks] Buffers" })
vim.keymap.set("n", "<leader>sf", function() snacks.picker.files() end, { desc = "[Snacks] Find files" })
vim.keymap.set("n", "<leader>sp", function() snacks.picker.projects() end, { desc = "[Snacks] Projects" })
vim.keymap.set("n", "<leader>sr", function() snacks.picker.recent() end, { desc = "[Snacks] Recent" })

vim.keymap.set("n", "<C-g>", function() snacks.lazygit() end, { desc = "[Snacks] Lazygit" })
vim.keymap.set("n", "<leader>gl", function() snacks.picker.git_log() end, { desc = "[Snacks] Git log" })
vim.keymap.set("n", "<leader>gd", function() snacks.picker.git_diff() end, { desc = "[Snacks] Git diff" })
vim.keymap.set("n", "<leader>gb", function() snacks.git.blame_line() end, { desc = "[Snacks] Git blame line" })
vim.keymap.set("n", "<leader>gB", function() snacks.gitbrowse() end, { desc = "[Snacks] Git browse" })

vim.keymap.set("n", "<leader>sg", function() snacks.picker.grep() end, { desc = "[Snacks] Grep" })
vim.keymap.set("n", "<leader>su", function() snacks.picker.undo() end, { desc = "[Snacks] Undo history" })
vim.keymap.set("n", "<leader>st", function() snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME", "BUG", "FIXIT", "HACK" } }) end)
vim.keymap.set("n", "<leader>sT", function() snacks.picker.todo_comments() end, { desc = "[TODO] Pick todos (with NOTE)" })

vim.keymap.set("n", "<leader>ut", "<cmd>UndotreeToggle<cr>", { desc = "Toggle undo-tree" })

vim.keymap.set("n", "<leader>/", function() require("Comment.api").toggle.linewise.current() end)
vim.keymap.set("v", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>")
vim.keymap.set("n", "<C-_>", function() require("Comment.api").toggle.linewise.current() end)
vim.keymap.set("v", "<C-_>", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>")

vim.keymap.set({ "n", "x", "o" }, "<leader>f", function() require("flash").jump() end, { desc = "[Flash] Jump" })
vim.keymap.set({ "n", "x", "o" }, "<leader>F", function() require("flash").treesitter() end, { desc = "[Flash] Treesitter" })
vim.keymap.set("c", "<c-f>", function() require("flash").toggle() end, { desc = "[Flash] Toggle Search" })
vim.keymap.set(
    { "n", "x", "o" },
    "<leader>j",
    function()
        require("flash").jump({
            search = { mode = "search", max_length = 0 },
            label = { after = { 0, 0 }, matches = false },
            jump = { pos = "end" },
            pattern = "^\\s*\\S\\?" -- match non-whitespace at stant plus any character (ignores empty lines)
        })
    end,
    { desc = "[Flash] Line jump" }
)
vim.keymap.set(
    { "n", "x", "o" },
    "<leader>k",
    function()
        require("flash").jump({
            search = { mode = "search", max_length = 0 },
            label = { after = { 0, 0 }, matches = false },
            jump = { pos = "end" },
            pattern = "^\\s*\\S\\?" -- match non-whitespace at stant plus any character (ignores empty lines)
        })
    end,
    { desc = "[Flash] Line jump" }
)

-- vim.keymap.set("x", "mI", function() multicursor.insertVisual() end, { desc = "Insert cursors at visual selection" })
-- vim.keymap.set("x", "mA", function() multicursor.appendVisual() end, { desc = "Append cursors at visual selection" })

vim.keymap.set("n", "<A-j>", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Go to next diagnostic" })
vim.keymap.set("n", "<A-k>", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Go to previous diagnostic" })
vim.keymap.set("n", "<leader>gd", "<CMD>Trouble diagnostics toggle<CR>", { desc = "[Trouble] Toggle buffer diagnostics" })
vim.keymap.set("n", "<leader>gs", "<CMD>Trouble symbols toggle focus=false<CR>", { desc = "[Trouble] Toggle symbols" })
vim.keymap.set("n", "<leader>gl", "<CMD>Trouble lsp toggle focus=false win.position=right<CR>", { desc = "[Trouble] Toggle LSP definitions/references/..." })
vim.keymap.set("n", "<leader>gq", "<CMD>Trouble qflist toggle<CR>", { desc = "[Trouble] Quickfix List" })

vim.keymap.set("n", "n", "nzz<Cmd>lua require('hlslens').start()<CR>", { desc = "Next match", noremap = true, silent = true })
vim.keymap.set("n", "N", "Nzz<Cmd>lua require('hlslens').start()<CR>", { desc = "Previous match", noremap = true, silent = true })
vim.keymap.set("n", "*", "*<Cmd>lua require('hlslens').start()<CR>", { desc = "Next match", noremap = true, silent = true })
vim.keymap.set("n", "#", "#<Cmd>lua require('hlslens').start()<CR>", { desc = "Previous match", noremap = true, silent = true })
vim.keymap.set("n", "g*", "g*<Cmd>lua require('hlslens').start()<CR>", { desc = "Next match", noremap = true, silent = true })
vim.keymap.set("n", "g#", "g#<Cmd>lua require('hlslens').start()<CR>", { desc = "Previous match", noremap = true, silent = true })
vim.keymap.set("n", "//", "<Cmd>noh<CR>", { desc = "Clear highlight", noremap = true, silent = true })

