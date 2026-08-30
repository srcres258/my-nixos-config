{ config, pkgs, lib, ... }:

{
  ############################################################
  # Prometheus
  ############################################################

  services.prometheus = {
    enable = true;

    # 只允许本机访问 Prometheus Web API。
    listenAddress = "127.0.0.1";
    port = 9090;

    # JVM 性能数据保留时间。
    # 如果磁盘空间充足，可以改成 30d / 90d。
    retentionTime = "15d";

    scrapeConfigs = [
      {
        job_name = "atm10-jvm";

        # Minecraft 的瞬时 GC / heap 变化比较值得观察，
        # 5s 是一个比较合理的起始值。
        scrape_interval = "5s";
        scrape_timeout = "4s";

        static_configs = [
          {
            targets = [
              "127.0.0.1:9404"
            ];

            labels = {
              service = "atm10";
              type = "minecraft";
            };
          }
        ];
      }
    ];
  };


  ############################################################
  # Pyroscope
  ############################################################

  services.pyroscope = {
    enable = true;

    # 只允许本机 Alloy / Grafana 访问。
    openFirewall = false;

    settings = {
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 4040;
      };
    };
  };


  ############################################################
  # Grafana Alloy
  ############################################################

  services.alloy = {
    enable = true;
    configPath = "/etc/alloy";

    extraFlags = [
      "--disable-reporting"
    ];
  };

  environment.etc."alloy/config.alloy".text = ''
    // Discover local processes.
    discovery.process "all" {
      refresh_interval = "30s"

      discover_config {
        exe         = true
        cwd         = true
        commandline = true
        username    = true
        uid         = true
        cgroup_path = true
      }
    }

    // Keep Java processes only.
    discovery.relabel "java" {
      targets = discovery.process.all.targets

      rule {
        action        = "keep"
        source_labels = ["__meta_process_exe"]
        regex         = ".*/java$"
      }

      rule {
        action       = "replace"
        target_label = "service_name"
        replacement  = "atm10"
      }
    }

    // Send profiles to the local Pyroscope instance.
    pyroscope.write "local" {
      endpoint {
        url = "http://127.0.0.1:4040"
      }

      external_labels = {
        environment = "home",
        application = "minecraft",
      }
    }

    // Continuously profile the ATM10 JVM.
    pyroscope.java "atm10" {
      targets    = discovery.relabel.java.output
      forward_to = [pyroscope.write.local.receiver]

      profiling_config {
        interval    = "30s"
        cpu         = true
        sample_rate = 100
        alloc       = "512k"
        lock        = "10ms"
      }
    }
  '';


  ############################################################
  # IMPORTANT:
  # Alloy pyroscope.java needs root process visibility.
  ############################################################

  # services.alloy 默认 DynamicUser = true。
  # discovery.process / pyroscope.java 官方要求：
  #
  #   * root
  #   * host PID namespace
  #
  # 因此覆盖 NixOS module 默认 service 设置。
  systemd.services.alloy.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "root";
  };


  ############################################################
  # Grafana
  ############################################################

  services.grafana = {
    enable = true;

    # 如果只希望通过 SSH tunnel / nginx 访问：
    #   http_addr = "127.0.0.1";
    #
    # 如果希望 LAN 中直接访问 Grafana：
    #   http_addr = "0.0.0.0";
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 13000;
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      # 生产环境建议改为 __file provider，
      # 下面后面单独解释。
      security = {
        secret_key = "CHANGE-THIS-TO-A-LONG-RANDOM-SECRET";
      };
    };


    ##########################################################
    # Declarative datasource provisioning
    ##########################################################

    provision = {
      enable = true;

      datasources.settings = {
        apiVersion = 1;

        datasources = [
          {
            name = "Prometheus";
            uid = "prometheus";
            type = "prometheus";
            access = "proxy";

            url = "http://127.0.0.1:9090";

            isDefault = true;

            editable = false;
          }

          {
            name = "Pyroscope";
            uid = "pyroscope";
            type = "grafana-pyroscope-datasource";
            access = "proxy";

            url = "http://127.0.0.1:4040";

            editable = false;

            jsonData = {
              minStep = "15s";
            };
          }
        ];
      };
    };
  };


  ############################################################
  # Firewall
  ############################################################

  # 只开放 Grafana。
  #
  # Prometheus 9090
  # Pyroscope  4040
  # JMX        9404
  #
  # 都只绑定 localhost，因此无需开放。
  networking.firewall.allowedTCPPorts = [
    3000
  ];
}

