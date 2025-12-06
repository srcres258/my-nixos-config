{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [ ./pure.nix ];

  programs.fish = {
    enable = true;

    functions = {
      fish_prompt = ''
        # 示例：简单用户@主机 + 当前目录 + 状态指示符
        function fish_prompt
          set -l last_status $status
          set -l cyan (set_color cyan)
          set -l yellow (set_color yellow)
          set -l red (set_color red)
          set -l green (set_color green)
          set -l normal (set_color normal)

          # 显示当前目录
          echo -n "$cyan$PWD$normal"

          # 如果上个命令失败，显示红色提示符
          if test $last_status -ne 0
            echo "$red❯$normal "
          else
            echo "$green❯$normal "
          end
        end
      '';
    };
  };
}

