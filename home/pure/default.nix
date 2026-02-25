{
    system,
    config,
    pkgs,
    lib,
    inputs,
    ...
}: let
    username = "srcres";

    javaPkg = pkgs.javaPackages.compiler.temurin-bin.jdk-21;
    scalaPkg = pkgs.scala_3;
in {
    imports = [
        ../options.nix
        ./himalaya.nix
        ./newsboat.nix
    ];

    home = {
        inherit username;
        homeDirectory = "/home/${username}";
    };
    home.sessionPath = [
        "~/.ghcup/bin"
    ];

    nixpkgs.config.allowUnfree = true;
    # nixpkgs.overlays = [
    #     (final: prev: {
    #         nur = {
    #             repos = {
    #                 srcres258 = import inputs.my-nur {
    #                     pkgs = final;
    #                 };
    #             };
    #         };
    #      })
    # ];

    home.packages = with pkgs; [
        cascadia-code

        qemu

        nil
        lua-language-server
        pyright
        taplo
        marksman

        imagemagick
        tectonic
        ripgrep
        git-extras
        git-credential-outlook

        codespell

        mpv

        write-good
        ncdu
        hyperfine
        fd

        eza

        nodejs_24
        electron
        pnpm

        pkgsCross.riscv64.stdenv.cc           # Linux GNU
        pkgsCross.riscv64-embedded.stdenv.cc  # bare-metal ELF
        pkgsCross.riscv32-embedded.stdenv.cc

        scons

        wireshark

        hexo-cli

        optnix
        nix-tree

        ffmpeg

        yt-dlp

        kubo

        hlint
        universal-ctags

        android-file-transfer

        unar

        jadx

        whisper-cpp
        spek
        fcrackzip

        thunderbird

# Ethereum
        inputs.go-ethereum-legacy-nixpkgs.legacyPackages.${system}.go-ethereum
        foundry-bin
        solc
        python312Packages.pyevmasm

# Nix language
        nixd
        nixpkgs-fmt

# Scala language
        scala-cli
        sbt
        inputs.mill-legacy-nixpkgs.legacyPackages.${system}.mill
        bloop
        ammonite
        scalafmt
        scalafix
        metals

# Rust language
        cargo
        rustc
        rustfmt
        clippy
        rust-analyzer

        (let
            base = pkgs.appimageTools.defaultFhsEnvArgs;
        in pkgs.buildFHSEnv (base // {
            name = "fhs";
            targetPkgs = pkgs:
            (base.targetPkgs pkgs) ++ (with pkgs; [
                pkg-config
                ncurses
                SDL2
                file

# ... add more dependencies here ...
            ]);
            profile = "export FHS=1";
            runScript = "bash";
            extraOutputsToInstall = ["dev"];
        }))

        gdb

# Go language
        gopls

# Verilog / SystemVerilog language
        verible

# Python language
        (python313.withPackages (ps: ((with ps; [
            numpy
            pandas
            matplotlib
            requests
            jupyter
            openai
            termcolor
            prompt-toolkit
            aprslib
            web3
            sphinx
            z3-solver
        ]) ++ (config.my.python.packageGenerator ps))))
        yapf
        hatch

# Haskell language
        (haskellPackages.ghcWithPackages (ps: with ps; [
            data-memocombinators
            mtl
        ]))
        cabal-install
        haskell-language-server
        stack

# Lean language
        elan
    ] ++ (with nur.repos; [
        srcres258.ag
        srcres258.jyyslide-util
    ]) ++ [ javaPkg scalaPkg ];
    home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";

        JAVA_HOME = "${javaPkg}";
        COURSIER_CACHE = "${config.xdg.cacheHome}/coursier";
        SBT_OPTS = "-Dsbt.ivy.home=${config.xdg.cacheHome}/ivy2 -Dsbt.global.base=${config.xdg.configHome}/sbt -Dsbt.coursier.home=${config.xdg.cacheHome}/coursier";

        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    };
    xdg.enable = true;
    xdg.cacheHome = builtins.toPath "/home/${config.home.username}/.cache";

    programs.yazi = {
        enable = true;

        plugins = with pkgs.yaziPlugins; {
            inherit toggle-pane;
        };

        keymap = {
            manager = {
                prepend_keymap = [
                    {
                        on = [ "<C-right>" ];
                        run = "plugin toggle-pane max-preview";
                        desc = "Roggle maxinize preview pane";
                    }
                ];
            };
        };

        settings = {
            preview = {
                max_width = 2400;
                max_height = 3600;
                image_filter = "lanczos3";
                image_quality = 90;
                tab_size = 2;
            };
        };
    };

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

            haskell-tools-nvim

            nvim-metals

            typescript-tools-nvim
        ]);
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

    programs.pandoc.enable = true;

    programs.fastfetch = {
        enable = true;
        settings = let
            logoFile = ./furry.lgo;
        in {
            modules = [
                "title"
                "separator"
                "os"
                "host"
                "kernel"
                "uptime"
                "packages"
                "shell"
                "display"
                "de"
                "wm"
                "wmtheme"
                "theme"
                "icons"
                "font"
                "cursor"
                "terminal"
                "terminalfont"
                "cpu"
                "gpu"
                "memory"
                "swap"
                "disk"
                "localip"
                "battery"
                "poweradapter"
                "locale"
                "break"
                "colors"
            ];
            logo = {
                type = "auto"; # Logo type: auto, builtin, small, file, etc.
                source = "${logoFile}"; # Built-in logo name or file path
                width = 35; # Width in characters (for image logos)
                height = 35; # Height in characters (for image logos)
                padding = {
                    top = 0; # Top padding
                    left = 0; # Left padding
                    right = 2; # Right padding
                };
                color = { # Override logo colors
                    "1" = "blue";
                    "2" = "green";
                };
            };
        };
    };

    programs.poetry.enable = true;

    programs.password-store.enable = true;

    programs.gpg.enable = true;

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-tty;
    };

    programs.opencode = {
        enable = true;
        settings = {
            provider = {
                openrouter = {
                    npm = "@ai-sdk/openai-compatible";
                    name = "OpenRouter";
                    options = {
                        baseURL = "https://openrouter.ai/api/v1";
                        apiKey = "{env:OPENROUTER_API_KEY}";
                    };
                };
            };
        };
    };

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

