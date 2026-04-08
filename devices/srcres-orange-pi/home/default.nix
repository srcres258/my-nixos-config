{ ... }: {
  # Keep host-specific Home Manager settings minimal for ARM SBC.
  home.username = "srcres";
  home.homeDirectory = "/home/srcres";
  home.stateVersion = "25.11";
}
