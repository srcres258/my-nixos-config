{ config
, pkgs
, lib
, inputs
, ...
}: {
  options.my.python.packageGenerator = lib.mkOption {
    type = lib.types.anything;
    default = ps: [ ];
    description = "Python package generator to offer additional Python packages.";
  };

  options.my.minimal = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Trim the profile for a storage-constrained host. It currently disables
      the Scala and TypeScript tooling that the shared Neovim configuration
      would otherwise pull in (JVM + Node, ~1.2 GiB).
    '';
  };
}

