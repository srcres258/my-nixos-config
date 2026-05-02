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

  xdg.configFile."opencode/oh-my-opencode.jsonc".source =
    json.generate "oh-my-opencode.jsonc" {
      agents = let
        ds = "deepseek/deepseek-v4-pro";
      in {
        sisyphus = {
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
      };
    };

  home.packages = with pkgs; [
    bun
  ];
}

