{ ... }: {
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        name = "srcres258";
        email = "src.res.211@gmail.com";
      };

      ui.editor = "nvim";
    };
  };
}

