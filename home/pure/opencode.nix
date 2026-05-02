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
    settings = {
      # Note: "$schema": "https://opencode.ai/config.json" is automatically added.
      permission = {
        "*" = "ask";
      };
    };
  };

  xdg.configFile."opencode/oh-my-openagent.jsonc".source =
    json.generate "oh-my-openagent.jsonc" (let
      ds = "deepseek/deepseek-v4-pro";
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
          model = ds;
        };
        prometheus = {
          model = ds;
        };
        atlas = {
          model = ds;
          variant = "max";
        };

        metis = {
          model = ds;
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
        mulitmodal-looker = {
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

