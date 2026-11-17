# Live audio relay: upstream HLS -> ffmpeg/Opus -> Icecast on this board.
#
# audiorelay (github:srcres258/audiorelay) owns the transcoding and the single
# Icecast source connection. Icecast is configured here rather than through
# services.icecast, because that module renders its XML with pkgs.writeText and
# would put the source password into the Nix store. Instead the password is read
# from a runtime file through a systemd credential and rendered into
# /run/icecast/icecast.xml, which only the service user can read.
{ lib, pkgs, inputs, ... }:

let
  # Same runtime secret directory as users.users.srcres.hashedPasswordFile.
  # Create it on the board with:
  #   sudo install -d -m 0700 /var/lib/nixos/secrets
  #   printf '%s\n' '<password>' |
  #     sudo tee /var/lib/nixos/secrets/audiorelay-source-password >/dev/null
  #   sudo chmod 600 /var/lib/nixos/secrets/audiorelay-source-password
  sourcePasswordFile = "/var/lib/nixos/secrets/audiorelay-source-password";

  icecastPort = 8000;

  # Placeholders are substituted at start. They are deliberately unique XML
  # comments so the replacement can never hit real configuration content.
  icecastTemplate = pkgs.writeText "icecast.xml.in" ''
    <?xml version="1.0"?>
    <icecast>
      <hostname>srcres-rpi</hostname>

      <limits>
        <clients>16</clients>
        <sources>1</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
        <burst-size>65535</burst-size>
      </limits>

      <authentication>
        <source-password>@@SOURCE_PASSWORD@@</source-password>
        <relay-password>@@RELAY_PASSWORD@@</relay-password>
        <admin-user>admin</admin-user>
        <admin-password>@@ADMIN_PASSWORD@@</admin-password>
      </authentication>

      <!-- Binds :: only; Linux defaults to bindv6only=0, so IPv4 clients are
           accepted through the IPv4-mapped range as well. -->
      <listen-socket>
        <port>${toString icecastPort}</port>
        <bind-address>::</bind-address>
      </listen-socket>

      <paths>
        <logdir>/var/log/icecast</logdir>
        <webroot>${pkgs.icecast}/share/icecast/web</webroot>
        <adminroot>${pkgs.icecast}/share/icecast/admin</adminroot>
      </paths>
    </icecast>
  '';

  renderIcecastConfig = pkgs.writeShellScript "icecast-render-config" ''
    set -eu
    umask 077

    password_file="''${CREDENTIALS_DIRECTORY:?CREDENTIALS_DIRECTORY is not set}/source-password"
    if [ ! -s "$password_file" ]; then
      echo "icecast: missing source password at $password_file" >&2
      exit 1
    fi
    source_password=$(cat "$password_file")

    # The value is substituted into XML text, which has no escaping for these
    # delimiters. Reject them instead of writing a malformed document.
    case "$source_password" in
      *[!A-Za-z0-9._~!@%^+=:-]*)
        echo "icecast: source password contains characters that cannot be" \
          "embedded in the generated XML" >&2
        exit 1
        ;;
    esac

    # The relay and admin passwords are local-only, so random values per start
    # are enough and no additional secret has to be provisioned.
    random_password() {
      head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | cut -c1-24
    }

    sed \
      -e "s|@@SOURCE_PASSWORD@@|$source_password|g" \
      -e "s|@@RELAY_PASSWORD@@|$(random_password)|g" \
      -e "s|@@ADMIN_PASSWORD@@|$(random_password)|g" \
      ${icecastTemplate} >"$RUNTIME_DIRECTORY/icecast.xml"
  '';
in
{
  imports = [ inputs.audiorelay.nixosModules.default ];

  services.audiorelay = {
    enable = true;

    input = "https://live.koryocdn.org/kctv/index.m3u8";

    # Username only: the password comes from sourcePasswordFile and never
    # appears in this URL, the Nix store, or the ffmpeg command line.
    output = "icecast://source@[::1]:${toString icecastPort}/tv.opus";

    sourcePasswordFile = sourcePasswordFile;

    bitrate = "32k";
    channels = 2;
    sampleRate = 48000;
    logLevel = "info";
  };

  # Icecast is started before audiorelay so the first source connection does not
  # race the listener socket.
  systemd.services.audiorelay = {
    after = [ "icecast.service" ];
    wants = [ "icecast.service" ];
  };

  systemd.services.icecast = {
    description = "Icecast audio streaming server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      RuntimeDirectory = "icecast";
      LogsDirectory = "icecast";

      # The service user cannot read /var/lib/nixos/secrets directly, so the
      # manager copies the file into a private credential directory first.
      LoadCredential = "source-password:${sourcePasswordFile}";

      ExecStartPre = renderIcecastConfig;
      ExecStart = "${lib.getExe pkgs.icecast} -c %t/icecast/icecast.xml";
      ExecReload = "${lib.getExe' pkgs.coreutils "kill"} -HUP $MAINPID";

      Restart = "on-failure";
      RestartSec = "5s";

      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
    };
  };

  # Listeners reach Icecast from the LAN; audiorelay itself makes only outbound
  # connections and needs no inbound port.
  networking.firewall.allowedTCPPorts = [ icecastPort ];
}
