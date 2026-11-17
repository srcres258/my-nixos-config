# Deliberately small home profile for the Raspberry Pi 4.
#
# The full ../pure profile closes over ~27 GiB: GHC for pandoc and
# pandoc-crossref, texlive, the Rust/Go/Zig/Lean/Coq toolchains, a JVM for
# jadx and scala, Electron plus Node, Qt wireshark and the scientific Python
# stack. A 64 GiB SD card cannot hold that next to the system closure and the
# Nix GC headroom, and none of it is useful on a headless board.
#
# Keep this list short: everything added here has to fit on the card. The
# aarch64 CI job makes those paths cheap to *fetch*, not small.
{ config
, lib
, pkgs
, ...
}:
let
  username = "srcres";
in
{
  imports = [
    ../options.nix

    ./git.nix
    ./jujutsu.nix
    ./fish.nix
    ./gh.nix

    ./neovim
    ./yazi
    ./pi-coding-agent
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Search, navigation and file handling. vim, git, wget, tmux, tree, file,
    # unzip, htop and the hardware probes come from the system profile.
    ripgrep
    fd
    eza
    fzf
    tldr
    ncdu
    unar
    jq
    git-extras

    # Nix maintenance.
    nix-tree
    nixpkgs-fmt

    # Bare Python for scripting; the numpy/pandas/jupyter stack stays on the
    # x86 hosts.
    python3

    # Language servers used by ./neovim. pyright is left out because it pulls
    # in a Node runtime; the rest are self-contained native binaries.
    nil
    lua-language-server
    taplo
    marksman
  ];

  # Turns off the Scala/TypeScript tooling in ./neovim (JVM + Node, ~1.2 GiB).
  my.minimal = true;

  # ./gh.nix enables this Go TUI as well; it is not wanted on the board.
  programs.gh-dash.enable = lib.mkForce false;

  xdg.enable = true;
  xdg.cacheHome = builtins.toPath "/home/${config.home.username}/.cache";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.fzf.enable = true;
  programs.fd.enable = true;
  programs.eza.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-tty;
  };

  programs.fastfetch.enable = true;
}
