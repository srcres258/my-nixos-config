{ lib
, pkgs
, configFile
}:
let
  shellScript = builtins.readFile ./vmctl.sh;
in
pkgs.writeShellApplication {
  name = "vmctl";

  excludeShellChecks = [
    "SC1090"
    "SC1091"
    "SC2016"
    "SC2154"
  ];

  runtimeInputs = [
    pkgs.coreutils
    pkgs.freerdp
    pkgs.virt-viewer
    pkgs.gnugrep
    pkgs.kmod
    pkgs.libvirt
    pkgs.pciutils
    pkgs.qemu
    pkgs.swtpm
    pkgs.util-linux
  ];

  text = ''
    CONFIG_FILE=${lib.escapeShellArg configFile}
  '' + shellScript;
}
