{
  ...
}: let
  gitignore = ./ignore;
in {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "srcres258";
        email = "src.res.211@gmail.com";
      };
      core = {
        editor = "nvim";
        excludesfile = "${gitignore}";
        autocrlf = "input";
      };
      http.postbuffer = 1048576000;
    };
    signing.key = "88079CCB3D29D2C3";
  };
  programs.lazygit.enable = true;
}

