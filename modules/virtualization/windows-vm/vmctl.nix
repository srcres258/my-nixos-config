{ lib
, pkgs
, configFile
}:
let
  shellScript = builtins.readFile ./vmctl.sh;
in
pkgs.writeShellApplication {
  name = "vmctl";

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
