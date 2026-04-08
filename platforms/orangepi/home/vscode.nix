{ system
, pkgs
, inputs
, ...
}:
let
  vscode-ext = pkgs.nix-vscode-extensions;
in
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.vscode-extensions.overlays.default
  ];

  home.packages = [
    pkgs.ltex-ls-plus
  ];

  programs.vscode =
    let
      vscode-pkgs = import inputs.vscode-legacy-nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      enable = true;
      package = vscode-pkgs.vscode;

      mutableExtensionsDir = true;

      profiles = {
        default = {
          extensions = (with vscode-pkgs.vscode-extensions; [
            rust-lang.rust-analyzer
          ]) ++ (
            let
              m = vscode-ext.vscode-marketplace;
            in
            with m; [
              # Core UI / workflow
              ms-ceintl.vscode-language-pack-zh-hans
              asvetliakov.vscode-neovim

              # AI coding helpers
              github.copilot
              sst-dev.opencode

              # Nix / C / Rust toolchain
              jnoortheen.nix-ide
              ms-vscode.cpptools
              ms-vscode.cmake-tools
              ms-vscode.makefile-tools

              # Docs and writing
              james-yu.latex-workshop
              ltex-plus.vscode-ltex-plus
              myriad-dreamin.tinymist
              yzhang.markdown-all-in-one
            ]
          );

          userSettings = {
            "editor.fontFamily" = "'Cascadia Code', 'monospace', monospace, 'Droid Sans Fallback'";
            "editor.fontSize" = 18;
            "editor.rulers" = [ 80 100 120 ];
            "editor.tabSize" = 2;
            "workbench.colorTheme" = "Night Owl";
            "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim-unwrapped}/bin/nvim";

            # Keep save-time build loops lightweight on Orange Pi.
            "latex-workshop.latex.autoBuild.run" = "onSave";
            "latex-workshop.view.pdf.viewer" = "tab";
          };
        };
      };
    };
}
