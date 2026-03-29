{
  pkgs,
  ...
}: {
  programs.neovim = let
    treesitter-parsers = pkgs.symlinkJoin {
      name = "treesitter-parsers";
      paths = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash c cpp css dockerfile go html java javascript json
        lua nix python regex rust toml typescript vim yaml markdown
        latex make haskell scala systemverilog sql fish solidity
      ];
    };
  in {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-treesitter-context
      playground

      nvim-lspconfig
      lsp-zero-nvim

      friendly-snippets

      blink-cmp

      catppuccin-nvim
      lualine-nvim
      barbar-nvim
      nvim-tree-lua
      rainbow-delimiters-nvim
      noice-nvim
      nvim-web-devicons

      codecompanion-nvim
      nvim-cmp

      lazydev-nvim
      which-key-nvim
      snacks-nvim
      nvim-autopairs
      trim-nvim
      undotree
      comment-nvim
      smartyank-nvim
      flash-nvim
      plenary-nvim
      todo-comments-nvim
      mini-ai
      # multicursor-nvim
      vim-wakatime

      nvim-lint
      trouble-nvim

      gitsigns-nvim
      mini-diff
      nvim-scrollbar
      nvim-hlslens
      nvim-colorizer-lua
      # showkeys
      nvim-lightbulb
      nvim-ufo

      lazy-nvim

      copilot-lua
      blink-copilot
      codecompanion-nvim
      fidget-nvim

      haskell-tools-nvim

      nvim-metals

      typescript-tools-nvim

      typst-vim
    ];
    extraLuaConfig = ''
      require('nvim-treesitter.configs').setup {
        ensure_installed = {},
        parser_install_dir = "${treesitter-parsers}",
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = { enable = true },

        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner"
            }
          },
          move = {
            enable = true,
            set_jumps = true, -- enable function-jumping features by ']m' or '[m'
                goto_next_start = { ["]m"] = "@function.outer" },
            goto_previous_start = { ["[m"] = "@function.outer" }
          }
        },

        -- commonly used features in addition
        context_commentstring = { enable = true }, -- integration with nvim-ts-context-commentstring
        autotag = { enable = true }, -- integration with nvim-ts-autotag to close up HTML/JSX tags automatically
        rainbow = { enable = true, extended_mode = true } -- rainbow blankets (requires nvim-ts-rainbow2)
      }

      vim.opt.rtp:prepend("${treesitter-parsers}")
    '' + (let
      metalsBinaryPath = "${pkgs.metals}";
      customReplace = builtins.replaceStrings ["{{METALS_BINARY_PATH}}"] [metalsBinaryPath];
    in customReplace (builtins.readFile ./init.lua));
    extraConfig = ''
      " Disable mappings for left and right arrow keys from plugins for SQL files.
      let g:dbext_default_CALCULATOR_enable = 0
      let g:loaded_dbext = 1
    '';
    extraPackages = with pkgs; [
      sqls # The SQL language server.
      metals
      coursier
      jdk17

      nodePackages.typescript
      nodePackages.typescript-language-server
    ];
  };
}
