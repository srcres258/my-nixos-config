{
    config,
    pkgs,
    lib,
    inputs,
    ...
}: {
    imports = [ ./pure ./system ];
}

