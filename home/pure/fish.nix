{
  config,
  ...
}: {
  programs.fish = {
      enable = true;

      interactiveShellInit = ''
          fish_vi_key_bindings insert

          set fish_cursor_default     block      blink
          set fish_cursor_insert      line       blink
          set fish_cursor_replace_one underscore blink
          set fish_cursor_visual      block

          source /home/${config.home.username}/fishrc.fish
      '';
  };

}

