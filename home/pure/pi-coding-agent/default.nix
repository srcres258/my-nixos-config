{ pkgs, inputs, ... }:

{
  programs.pi-coding-agent = {
    enable = true;
    package = inputs.pi.packages.${pkgs.system}.default;
  };
}

