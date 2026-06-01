{ config
, ...
}: {
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      fish_vi_key_bindings insert

      set fish_cursor_default     block      blink
      set fish_cursor_insert      line       blink
      set fish_cursor_replace_one underscore blink
      set fish_cursor_visual      block
      
      # ===== 语法高亮配色 =====
      set -U fish_color_command      brblue          # 命令名 + sudo/precommand (粗体蓝)
      set -U fish_color_keyword       brcyan --bold   # if/for/while/function 关键字
      set -U fish_color_param         brwhite         # 普通参数 (白)
      set -U fish_color_option        bryellow        # -flag / --option (黄)
      set -U fish_color_quote         brmagenta       # "字符串" (品红)
      set -U fish_color_redirection   cyan            # > >> < 重定向
      set -U fish_color_end           brmagenta       # ; & |
      set -U fish_color_error         red --bold      # 无效命令/语法错误 (粗红)
      set -U fish_color_comment       brblack --dim   # # 注释
      set -U fish_color_operator      bryellow        # * ~ 通配/运算符
      set -U fish_color_escape        cyan            # \n \t 转义
      set -U fish_color_valid_path    --underline     # 存在路径加下划线

      # ===== 自动建议 & 选中 =====
      set -U fish_color_autosuggestion 444 --dim
      set -U fish_color_selection      white --background=brblue

      # ===== sudo 变通：打 s + 空格 自动展开为 sudo =====
      abbr -a -g s sudo

      source /home/${config.home.username}/fishrc.fish
    '';
  };

}

