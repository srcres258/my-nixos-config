{ config, pkgs, lib, ... }:

{
  programs.zed-editor = {
    enable = true;

    # 可选：如果你希望 settings.json 完全由 HM 接管，改成 false
    # false = 更“纯”的声明式
    # true  = Zed UI 里改设置后，HM 会做合并/保留一定动态内容
    mutableUserSettings = false;
    mutableUserKeymaps = false;
    mutableUserTasks = false;
    mutableUserDebug = false;

    defaultEditor = false;

    # 可选：如果你会用 Zed Remote Development
    installRemoteServer = true;

    # 给 Zed 里的 LSP / formatter / 外部命令补 PATH
    extraPackages = with pkgs; [
      nixd
      nil
      alejandra
      rust-analyzer
      clang-tools
      nodejs
      typescript-language-server
      pyright
      basedpyright
      black
      ripgrep
      fd
      git
    ];

    # 启动时自动安装的扩展
    extensions = [
      "nix"
      "toml"
      "rust"
      "python"
      "html"
      "dockerfile"
      "make"
      "zig"
    ];

    userSettings = {
      # -------------------------
      # 基础编辑体验
      # -------------------------
      vim_mode = true;
      hour_format = "hour24";
      relative_line_numbers = true;
      load_direnv = "shell_hook";
      format_on_save = "on";
      autosave = "off";

      theme = {
        mode = "system";
        dark = "One Dark";
        light = "One Light";
      };

      ui_font_size = 16;
      buffer_font_size = 16;

      # -------------------------
      # AI：编辑预测（补全）
      # 可选值常见有：zed / copilot / none
      # -------------------------
      features = {
        edit_predictions = {
          provider = "copilot";
          # 若你想用 Zed 自带预测可改成 "zed"
          # 若你想走 Copilot 预测可改成 "copilot"
        };
      };

      # -------------------------
      # AI：模型 provider 配置
      # 这里只声明 provider 的 endpoint / 额外参数
      # API key 建议走环境变量，不要硬编码
      # -------------------------
      language_models = {
        openai = {
          api_url = "https://api.openai.com/v1";
        };

        # 如果你有 OpenAI-compatible 网关，也可以自定义
        # 具体 provider id / schema 以你使用的 Zed 版本为准
        # openrouter = {
        #   api_url = "https://openrouter.ai/api/v1";
        # };
      };
    };
  };
}

