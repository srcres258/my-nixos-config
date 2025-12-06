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

    prompt = ''
      function fish_prompt
        set -l last_status $status
        set -l cyan  (set_color cyan)
        set -l yellow (set_color yellow)
        set -l red    (set_color red)
        set -l blue   (set_color blue)
        set -l green  (set_color green)
        set -l normal (set_color normal)

        # 第一行：当前目录 + git 信息
        echo -n "$cyan$PWD$normal"
        __fish_git_prompt " %s"

        # 第二行：如果上个命令失败就显示红色 >
        if test $last_status -ne 0
          echo -n "$red>$normal "
        else
          echo -n "$green>$normal "
        end
      end
    '';
  };
}

