{
  system,
  pkgs,
  inputs,
  ...
}: let
  vscode-ext = pkgs.nix-vscode-extensions;
  ltex-jdk = pkgs.javaPackages.compiler.temurin-bin.jdk-21;
in {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.vscode-extensions.overlays.default
  ];

  home.packages = [ pkgs.ltex-ls-plus ltex-jdk ];

  programs.vscode = let
    vscode-pkgs = import inputs.vscode-legacy-nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    enable = true;
    package = vscode-pkgs.vscode;

    mutableExtensionsDir = true;

    profiles = {
      default = {
        extensions = ((with pkgs.vscode-extensions; [
          # Rust
          rust-lang.rust-analyzer
        ]) ++ (let
          m = vscode-ext.vscode-marketplace;
        in with m; [
          ms-ceintl.vscode-language-pack-zh-hans

          wayou.vscode-todo-highlight
          wakatime.vscode-wakatime
          yzane.markdown-pdf
          gruntfuggly.todo-tree

          # Icons
          vscode-icons-team.vscode-icons

          # Theme
          sdras.night-owl

          # VSCode Neovim
          asvetliakov.vscode-neovim

          # Copilot
          github.copilot

          # OpenCode
          sst-dev.opencode

          # TOML
          tamasfe.even-better-toml

          # C / C++
          ms-vscode.cpptools
          ms-vscode.cmake-tools
          ms-vscode.cpptools-extension-pack
          hars.cppsnippets

          # Makefile
          ms-vscode.makefile-tools

          # Scala
          scala-lang.scala
          scala-lang.scala-snippets
          scalameta.metals

          # SystemVerilog / Verilog / VHDL
          mshr-h.veriloghdl
          rjyoung.vscode-modern-vhdl-support

          # Nix
          jnoortheen.nix-ide

          # Haskell
          haskell.haskell
          justusadam.language-haskell
          hoovercj.haskell-linter

          # Python
          ms-python.python
          ms-python.debugpy
          ms-python.vscode-python-envs
          kamilturek.vscode-pyproject-toml-snippets

          # Jupyter Notebook
          ms-toolsai.jupyter
          ms-toolsai.jupyter-keymap
          ms-toolsai.vscode-jupyter-slideshow
          ms-toolsai.vscode-jupyter-cell-tags

          # Solidity
          nomicfoundation.hardhat-solidity

          # HTML
          sidthesloth.html5-boilerplate
          ecmel.vscode-html-css
          zignd.html-css-class-completion

          # JS and TS
          ms-vscode.vscode-typescript-next
          leizongmin.node-module-intellisense
          rvest.vs-code-prettier-eslint
          ms-vscode.js-debug
          dsznajder.es7-react-js-snippets
          msjsdiag.vscode-react-native
          ecmel.vscode-html-css
          bradlc.vscode-tailwindcss

          # CSS
          sysoev.language-stylus

          # Rust
          jscearcy.rust-doc-viewer

          # Lean
          leanprover.lean4

          # LaTeX
          james-yu.latex-workshop
          ltex-plus.vscode-ltex-plus

          # Typst
          myriad-dreamin.tinymist

          # Architecture
          # x86_64
          m."13xforever"."language-x86-64-assembly"
          # riscv
          sunshaoce.risc-v

          # Blogging
          fantasy.vscode-hexo-utils
        ]));

        userSettings = let
          toSameValAttrSet = keys: v: builtins.foldl' (acc: x: acc // {"${x}" = v;}) {} keys;
          toIgnoreAttrSet = keys: toSameValAttrSet keys "ignore";
        in {
          "editor.fontFamily" = "'Cascadia Code', 'monospace', monospace, 'Droid Sans Fallback'";
          "editor.fontSize" = 18;
          "nix.enableLanguageServer" = true;
          "editor.rulers" = [80 100 120];
          "editor.tabSize" = 2;
          "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim-unwrapped}/bin/nvim";
          "extensions.experimental.affinity" = {
            "asvetliakov.vscode-neovim" = 1;
          };

          "files.autoGuessEncoding" = true;
          "editor.cursorSmoothCaretAnimation" = true;
          "editor.smoothScrolling" = true;
          "editor.cursorBlinking" = "smooth";
          "editor.mouseWheelZoom" = false;
          "editor.wordWrap" = "off";
          "editor.suggest.snippetsPreventQuickSuggestions" = false;
          "editor.acceptSuggestionOnEnter" = "smart";
          "editor.suggestSelection" = "recentlyUsed";
          "window.dialogStyle" = "custom";
          "debug.showBreakpointsInOverviewRuler" = true;

          # Type annotations for TypeScript
          "typescript.inlayHints.parameterNames.enabled" = "all";
          "typescript.inlayHints.parameterTypes.enabled" = true;
          "typescript.inlayHints.variableTypes.enabled" = true;
          "typescript.inlayHints.propertyDeclarationTypes.enabled" = true;
          "typescript.inlayHints.functionLikeReturnTypes.enabled" = true;

          "workbench.colorTheme" = "Night Owl";
          "workbench.iconTheme" = "vscode-icons";

          # LaTeX workshop settings
          "latex-workshop.latex.tools" = [
            {
              name = "xelatex";
              command = "xelatex";
              args = [
                  "-synctex=1"
                  "-interaction=nonstopmode"
                  "-file-line-error"
                  "%DOC%"
              ];
            }
            {
              name = "bibtex";
              command = "bibtex";
              args = [
                  "%DOCFILE%"
              ];
            }
          ];
          "latex-workshop.latex.recipes" = [
            {
              name = "xelatex";
              tools = ["xelatex"];
            }
            {
              name = "xelatex -> bibtex -> xelatex*2";
              tools = ["xelatex" "bibxtex" "xelatex" "xelatex"];
            }
          ];
          "latex-workshop.formatting.latexindent.path" = "latexindent";
          # 保存时自动编译
          "latex-workshop.latex.autoBuild.run" = "onSave";
          # PDF 预览位置：右侧 Tab（最推荐）
          "latex-workshop.view.pdf.viewer" = "tab";
          # 反向同步（双击 PDF 跳回 tex 对应行，非常好用）
          "latex-workshop.view.pdf.internal.synctex.keybinding" = "double-click";

          # LTeX+ settings
          "ltex.enabled" = true;
          "ltex.language" = "en-US";
          # 开启 "挑剔规则". 学术写作时强烈推荐.
          "ltex.additionalRules.enablePickyRules" = true;
          # 个人/项目常用单词 (避免专有名词拼写错误)
          "ltex.dictionary" = {
            en-US = [
              "LSTM" "GAN" "Transformer" "BERT" "ReLU" "Adam" "SGD"
              "GitHub" "arXiv" "NeurIPS" "ICLR" "CVPR" "ECCV"
              "pretrained" "fine-tune" "fine-tuning" "fine-tuned"
              "state-of-the-art" "SOTA" "TODO" "FIXME"
            ];
          };
          # 非常常见的禁用规则 (学术写作误报率最高的前几项)
          "ltex.disabledRules" = {
            en-US = [
              "MORFOLOGIK_RULE_EN_US"
              "EN_QUOTES"
              "DASH_RULE"
              "PUNCTUATION_PARAGRAPH_END"
              "COMMA_PARENTHESIS_WHITESPACE"
              "SENTENCE_WHITESPACE"
              "UPPERCASE_SENTENCE_START"
            ];
          };
          # LaTeX 特殊命令/环境处理
          "ltex.latex.commands" = toIgnoreAttrSet [
            "\\todo"
            "\\todo[inline]"
            "\\cite"
            "\\citep"
            "\\citet"
            "\\ref"
            "\\eqref"
            "\\SI"
            "\\qty"
            "\\SIrange"
            "\\textbf"
            "\\textit"
          ];
          "ltex.latex.environments" = toIgnoreAttrSet [
            "align"
            "align*"
            "equation"
            "equation*"
            "gather"
            "multline"
            "verbatim"
            "lstlisting"
            "minted"
            "tikzpicture"
          ];
          # 性能与体验平衡
          "ltex.checkFrequency" = "save";
          "ltex.diagnosticSeverity" = "information";

          "ltex.ltex-ls.path" = "${pkgs.ltex-ls-plus}";
          "ltex.java.path" = "${ltex-jdk}/bin/java";
        };
      };
    };
  };
}

