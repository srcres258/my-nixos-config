{
    config,
    pkgs,
    lib,
    inputs,
    ...
}: {
    imports = [ ./pure.nix ./system.nix ];
}

