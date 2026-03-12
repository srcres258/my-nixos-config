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
      mgr = {
        prepend_keymap = [
          {
            on = [ "<C-right>" ];
            run = "plugin toggle-pane max-preview";
            desc = "Roggle maxinize preview pane";
          }
          {
            on = ["g" "c"];
            run = "plugin vcs-files";
            desc = "Show Git file changes";
          }
          {
            on = "M";
            run = "plugin mount";
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

      plugin = {
        prepend_preloaders = [
          # Replace magick, image, video with mediainfo
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }
          # Adobe Photoshop is image/adobe.photoshop, already handled above
          # Adobe Illustrator
          {
            mime = "application/postscript";
            run = "mediainfo";
          }
          {
            mime = "application/illustrator";
            run = "mediainfo";
          }
          {
            mime = "application/dvb.ait";
            run = "mediainfo";
          }
          {
            mime = "application/vnd.adobe.illustrator";
            run = "mediainfo";
          }
          {
            mime = "image/x-eps";
            run = "mediainfo";
          }
          {
            mime = "application/eps";
            run = "mediainfo";
          }
          {
            url = "*.{ai,eps,ait}";
            run = "mediainfo";
          }
        ];

        prepend_previewers = [
          {
            mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
            run = "ouch";
          }

          # Replace magick, image, video with mediainfo
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
          {
            mime = "application/subrip";
            run = "mediainfo";
          }
          # Adobe Photoshop is image/adobe.photoshop, already handled above
          # Adobe Illustrator

          {
            mime = "application/postscript";
            run = "mediainfo";
          }
          {
            mime = "application/illustrator";
            run = "mediainfo";
          }
          {
            mime = "application/dvb.ait";
            run = "mediainfo";
          }
          {
            mime = "application/vnd.adobe.illustrator";
            run = "mediainfo";
          }
          {
            mime = "image/x-eps";
            run = "mediainfo";
          }
          {
            mime = "application/eps";
            run = "mediainfo";
          }
        ];


        # For a large file like Adobe Illustrator, Adobe Photoshop, etc
        # you may need to increase the memory limit if no image is rendered.
        # https://yazi-rs.github.io/docs/configuration/yazi#tasks
        tasks = {
          image_alloc = 1073741824; # = 1024*1024*1024 = 1024MB
        };
      };
    };

    initLua = ./init.lua;
  };
}

