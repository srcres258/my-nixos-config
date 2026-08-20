{ pkgs
, config
, ...
}:
let
  # FHS wrapper for npm-installed opencode binary.
  # The npm package opencode-ai ships a dynamically linked native binary
  # that cannot run on NixOS directly. This wrapper provides the standard
  # FHS library paths at runtime via buildFHSEnv (bubblewrap sandbox).
  #
  # The actual binary is located at:
  #   ~/.node_modules/lib/node_modules/opencode-ai/bin/.opencode
  # and is invoked by the Node.js wrapper at:
  #   ~/.node_modules/lib/node_modules/opencode-ai/bin/opencode
  fhsWrapper = pkgs.buildFHSEnv {
    name = "opencode";
    targetPkgs = pkgs: with pkgs; [
      glibc
      zlib
      stdenv.cc.cc.lib
      openssl
      ncurses
    ];
    runScript = "${pkgs.writeShellScript "opencode-fhs" ''
      exec "${config.home.homeDirectory}/.node_modules/lib/node_modules/opencode-ai/bin/opencode" "$@"
    ''}";
    extraOutputsToInstall = [ "dev" ];
  };

  json = pkgs.formats.json {};
in
{
  programs.opencode = {
    enable = true;
    package = fhsWrapper;
    # Note: There are some issues around `settings` option.
    # The generated path is ~/.config/opencode/config.json
    # Rather than ~/.config/opencode/opencode.json.
    # So specify the config file manually as mentioned beneath.
  };

  xdg.configFile."opencode/opencode.json".source =
    json.generate "opencode.json" {
      "$schema" = "https://opencode.ai/config.json";
      permission = {
        read = "allow";
        edit = "ask";
        glob = "allow";
        grep = "allow";
        bash = {
          "*" = "ask";
          "ls *" = "allow";
          "cat *" = "allow";
          "grep *" = "allow";
          "head *" = "allow";
          "tail *" = "allow";
          "wc *" = "allow";
          "echo *" = "allow";
          "sed *" = "allow";
          "find *" = "allow";
          "sort *" = "allow";
          "awk *" = "allow";
          "file *" = "allow";

          "git status *" = "allow";
          "git diff *" = "allow";
          "git log *" = "allow";
        };
        task = "allow";
        skill = "allow";
        lsp = "allow";
        webfetch = "allow";
        websearch = "allow";
        external_directory = "ask";
        doom_loop = "ask";
      };
      skills = {
        paths = [ "~/.agents/skills" ];
      };
      plugin = [
        "oh-my-openagent@latest"
      ];
      provider = {
        micuapi = {
          options = {
            baseURL = "https://www.micuapi.ai/v1";
          };
          models = {
            "gpt-5.4-mini" = {
              name = "GPT-5.4 Mini";
              limit = {
                context = 400000;
                output = 128000;
              };
            };
          };
        };
      };
    };

  xdg.configFile."opencode/oh-my-openagent.jsonc".source =
    json.generate "oh-my-openagent.jsonc" (let
      #qwen = "alibaba-cn/qwen3.6-plus";
      gpt = "openai/gpt-5.4-mini";
      minimax = "minimax-cn/MiniMax-M3";
    in {
      agents = {
        sisyphus = {
          model = minimax;
        };
        sisyphus-junior = {
          model = minimax;
        };
        hephaestus = {
          model = gpt;
        };
        prometheus = {
          model = gpt;
        };
        atlas = {
          model = gpt;
        };

        metis = {
          model = gpt;
        };
        momus = {
          model = minimax;
        };

        oracle = {
          model = minimax;
        };
        librarian = {
          model = minimax;
        };
        explore = {
          model = minimax;
        };
        multimodal-looker = {
          model = minimax;
        };

        general = {
          model = minimax;
        };
        build = {
          model = minimax;
        };
      };
      categories = let
        minimax-model = {
          model = minimax;
        };
      in {
        visual-engineering = minimax-model;
        ultrabrain = minimax-model;
        deep = minimax-model;
        artistry = minimax-model;
        quick = minimax-model;
        unspecified-low = minimax-model;
        unspecified-high = minimax-model;
        writing = minimax-model;
      };
    });

  home.packages = with pkgs; [
    bun
  ];
}

