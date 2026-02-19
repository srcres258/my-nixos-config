{
    config,
        pkgs,
        lib,
        inputs,
        ...
}: {
    imports = [ ./pure ];

    programs.fish = {
        enable = true;

        interactiveShellInit = ''
            function fish_prompt
                # 示例：带 git 分支的提示符
                set -l cwd (prompt_pwd)
                if git rev-parse --git-dir > /dev/null 2>&1
                    set -l branch (git rev-parse --abbrev-ref HEAD)
                        echo -n "[$cwd ($branch)] > "
                else
                    echo -n "[$cwd] > "
                end
            end
        '';
    };
}

