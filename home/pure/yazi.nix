{
  pkgs,
  ...
}: {
  programs.yazi = {
    enable = true;

    plugins = with pkgs.yaziPlugins; {
      # UI / 外观增强
      inherit
        full-border       # 全边框美化，现代感强
        yatline           # 高度可定制的 header / statusline
        starship;         # 在 Yazi 头部显示 Starship prompt

      # Git 集成与版本控制
      inherit
        git               # 显示 git 状态图标、变更文件（资深开发者必装）
        vcs-files;        # 更细粒度的 git 文件变更预览

      # 挂载 / 解压 / 归档管理
      inherit
        mount             # 磁盘挂载、卸载、弹出（U 盘、ISO 等常用）
        ouch;             # 压缩/解压增强（支持更多格式）

      # 预览与内容增强
      inherit
        mediainfo         # 媒体文件（视频/音频/图片）详细元数据预览
        glow              # Markdown 漂亮渲染预览
        duckdb            # CSV/TSV/Parquet 等数据文件表格化预览（数据从业者爱用）
        piper;            # 任意 shell 命令输出作为预览器（极度灵活）

      # 导航与跳转
      inherit
        jump-to-char      # vim 风格 f<char> 快速跳转
        relative-motions  # 相对行号移动
        smart-enter;      # 智能进入目录/文件

      # 其他高阶
      inherit
        time-travel       # 浏览 BTRFS/ZFS 快照（备份/时间旅行）
        toggle-pane;
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
}

