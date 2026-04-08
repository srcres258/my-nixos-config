{ ... }: {
  home.username = "srcres";
  home.homeDirectory = "/home/srcres";
  home.stateVersion = "25.11";

  # Orange Pi keeps desktop parity without video wallpaper service.
  programs.mpvpaper.enable = false;

  # Ensure lightweight terminal defaults suitable for SBC resources.
  programs.kitty.settings = {
    enable_audio_bell = false;
    remember_window_size = false;
  };
}
