{ config
, pkgs
, lib
, ...
}: {
  imports = [
    ./pure
    ./system
  ];
}

