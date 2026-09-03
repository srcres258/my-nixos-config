{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  networking.wg-quick.interfaces.wg0 = {
    address = [
      "172.24.0.5/32"
      "fd04:7c16:7fe7::5/128"
    ];

    privateKeyFile = "/var/lib/private/wireguard/privatekey";

    peers = [
      {
        publicKey = "K1BUYi3Dt7iJKcqijPlobpJ6rupbI+bPjgpDamTpVB0=";

        endpoint = "my-home-network.srcres.top:51145";

        allowedIPs = [
          "172.24.0.0/24"
          "fd04:7c16:7fe7::/64"
          "172.16.0.0/16"
        ];

        persistentKeepalive = 25;
      }
      {
        publicKey = "+OfyQNE7je3i0Aa0dkxJSXHt/TLJpyKv1Xz9/18jk1Q=";

        endpoint = "my-server.srcres.top:51145";

        allowedIPs = [
          "172.24.0.0/24"
          "fd04:7c16:7fe7::/64"
          "172.16.0.0/16"
        ];

        persistentKeepalive = 25;
      }
    ];
  };
}

