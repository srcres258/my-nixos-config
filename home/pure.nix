{
    config,
    pkgs,
    lib,
    inputs,
    ...
}: let
    javaPkg = pkgs.javaPackages.compiler.temurin-bin.jdk-21;
    scalaPkg = pkgs.scala_3;
in {
    home = rec {
        username = "srcres";
        homeDirectory = "/home/${username}";
    };

    nixpkgs.config.allowUnfree = true;

    home.packages = with pkgs; [
        cascadia-code

        qemu

        fastfetch

        nil
        lua-language-server
        rust-analyzer
        pyright
        taplo
        marksman

        imagemagick
        tectonic
        ripgrep
        git-extras

        codespell

        mpv

        write-good
        ncdu
        hyperfine
        fd

        (python313.withPackages (ps: with ps; [
            numpy
            pandas
            matplotlib
            requests
            jupyter
        ]))

        eza

        kdePackages.okular

        openssl

        nodejs_24

        ghc
        cabal-install

        pkgsCross.riscv64.stdenv.cc           # Linux GNU
        pkgsCross.riscv64-embedded.stdenv.cc  # bare-metal ELF
        pkgsCross.riscv32-embedded.stdenv.cc

# Scala language
        scala-cli
        sbt
        mill
        metals
        bloop
        ammonite
        scalafmt
        scalafix

        (let
             base = pkgs.appimageTools.defaultFhsEnvArgs;
         in pkgs.buildFHSEnv (base // {
             name = "fhs";
             targetPkgs = pkgs:
             (base.targetPkgs pkgs) ++ (with pkgs; [
                 pkg-config
                 ncurses
                 SDL2

# ... add more dependencies here ...
             ]);
             profile = "export FHS=1";
             runScript = "bash";
             extraOutputsToInstall = ["dev"];
         }))

        gdb

# Go language
        gopls
    ] ++ [ javaPkg scalaPkg ];
    home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";

        JAVA_HOME = "${javaPkg}";
        COURSIER_CACHE = "${config.xdg.cacheHome}/coursier";
        SBT_OPTS = "-Dsbt.ivy.home=${config.xdg.cacheHome}/ivy2 -Dsbt.global.base=${config.xdg.configHome}/sbt -Dsbt.coursier.home=${config.xdg.cacheHome}/coursier";
    };

    programs.kitty = {
        enable = true;
        settings = {
            font_family = "Cascadia Mono PL";
            font_size = 15;

            background_opacity = 0.8;
            dynamic_background_opacity = "yes";

            allow_remote_control = "yes";

            strip_trailing_spaces = "smart";

# Cursor animations
            cursor_blink_interval = "-1 ease-in-out";
            cursor_stop_blinking_after = 0;
            cursor_trail = 1;
            cursor_trail_decay = "0.1 0.4";
            cursor_trail_start_threshold = 5;
            cursor_trail_color = "none";
        };
        environment = config.home.sessionVariables;
    };

    programs.wofi = {
        enable = true;
        settings = {
            term = "kitty";
        };
    };

    programs.vscode = {
        enable = true;
# TODO
    };

    programs.yazi = {
        enable = true;
# TODO
    };

    programs.neovim = let
        treesitter-parsers = pkgs.symlinkJoin {
            name = "treesitter-parsers";
            paths = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
                bash c cpp css dockerfile go html java javascript json
                lua nix python regex rust toml typescript vim yaml markdown
                latex make haskell scala systemverilog sql fish
            ];
        };
    in {
        enable = true;
        plugins = (with pkgs.vimPlugins; [
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
        ]);
        extraLuaConfig = (builtins.readFile ./init.lua) + ''
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
        '';
        extraConfig = ''
            " Disable mappings for left and right arrow keys from plugins for SQL files.
            let g:dbext_default_CALCULATOR_enable = 0
            let g:loaded_dbext = 1
        '';
        extraPackages = with pkgs; [
            sqls # The SQL language server.
        ];
    };

    programs.lazygit.enable = true;

    programs.fzf.enable = true;

    programs.texlive = {
        enable = true;
        extraPackages = tpkgs: {
            inherit (tpkgs)
                collection-basic
                collection-latex
                collection-latexextra
                collection-fontsrecommended
                collection-langchinese
                collection-bibtexextra
# collection-science
                collection-pictures
                collection-publishers;
        };
    };

    programs.pgcli.enable = true;

    programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
    };

    programs.go.enable = true;

    fonts.fontconfig = {
        defaultFonts = {
            emoji = [ "Noto Color Emoji" ];
            monospace = [
                "Noto Sans Mono CJK SC"
                "Sarasa Mono SC"
                "DejaVu Sans Mono"
            ];
            sansSerif = [
                "Noto Sans CJK SC"
                "Source Han Sans SC"
                "DejaVu Sans"
            ];
            serif = [
                "Noto Serif CJK SC"
                "Source Han Serif SC"
                "DejaVu Serif"
            ];
        };
    };

# !IMPORTANT!
# This option should NOT be changed, except for installation
# for a completely new machine or a new user.
    home.stateVersion = "25.05";
}

