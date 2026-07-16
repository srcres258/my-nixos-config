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
      provider = let
        codex = {
          name = "GPT-5.3 Codex";
          limit = {
            context = 400000;
            output = 128000;
          };
        };
      in {
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
      ds = "deepseek/deepseek-v4-pro";
      #qwen = "alibaba-cn/qwen3.6-plus";
      gpt = "openai/gpt-5.4-mini";
    in {
      agents = {
        sisyphus = {
          model = ds;
          reasoningEffort = "high";
        };
        sisyphus-junior = {
          model = ds;
          reasoningEffort = "high";
        };
        hephaestus = {
          model = gpt;
        };
        prometheus = {
          model = gpt;
        };
        atlas = {
          model = gpt;
          variant = "max";
        };

        metis = {
          model = gpt;
          variant = "max";
        };
        momus = {
          model = ds;
          reasoningEffort = "high";
        };

        oracle = {
          model = ds;
          variant = "max";
        };
        librarian = {
          model = ds;
          variant = "max";
        };
        explore = {
          model = ds;
          variant = "max";
        };
        multimodal-looker = {
          model = gpt;
          variant = "max";
        };

        general = {
          model = ds;
          variant = "max";
        };
        build = {
          model = ds;
          variant = "max";
        };
      };
      categories = let
        ds-max = {
          model = ds;
          variant = "max";
        };
      in {
        visual-engineering = ds-max;
        ultrabrain = ds-max;
        deep = ds-max;
        artistry = ds-max;
        quick = ds-max;
        unspecified-low = ds-max;
        unspecified-high = ds-max;
        writing = ds-max;
      };
    });

  home.packages = with pkgs; [
    bun
  ];
}

