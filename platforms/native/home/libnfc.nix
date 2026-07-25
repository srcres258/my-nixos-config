{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libnfc
  ];

  home.file.".nfc/libnfc.conf".text = ''
    allow_autoscan = false
    allow_intrusive_scan = false
    log_level = 1

    device.name = "PN532 UART"
    device.connstring = "pn532_uart:/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0"
  '';
}

