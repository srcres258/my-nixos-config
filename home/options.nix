{
    config,
    pkgs,
    lib,
    inputs,
    ...
}: {
    options.my.python.packageGenerator = lib.mkOption {
        type = lib.types.anything;
        default = ps: [];
        description = "Python package generator to offer additional Python packages.";
    };
}

