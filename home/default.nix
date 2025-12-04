{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [ ./pure.nix ./full.nix ];
}

