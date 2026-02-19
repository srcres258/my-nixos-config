{
  pkgs,
  ...
}: {
  # 全局启用 Himalaya（安装二进制 + 基本设置）
  programs.himalaya.enable = true;

  # 邮件账户定义（这里以 Outlook / Microsoft 365 为例）
  accounts.email.accounts = {
    outlook = {
      # 基本信息
      address = "srcres258@furdevs.cn";  # 你的 Outlook 邮箱
      realName = "Haowen Hu";                  # 显示名称
      userName = "srcres258@furdevs.cn"; # 通常和 address 一样
      primary = true;

      # 不需要再配置 imap/smtp/msmtp/mbsync，因为 Himalaya 会用自己的 backend
      # （Himalaya 支持 IMAP + OAuth2，不依赖 mbsync）

      # 启用 Himalaya 支持
      himalaya = {
        enable = true;

        # 这里传入 TOML 片段（直接对应 ~/.config/himalaya/config.toml 中的 [accounts.outlook] 部分）
        # 参考：https://github.com/pimalaya/himalaya/blob/master/config.sample.toml
        settings = {
          # 账户名称（在 himalaya 命令中用 -a outlook 指定）
          default = true;  # 可选：设为默认账户

          # 邮箱地址（通常和上面一致）
          email = "srcres258@furdevs.cn";

          # 使用 Microsoft 365 / Outlook 的 IMAP + OAuth2
          backend = {
            type = "imap";
            host = "outlook.office365.com";
            port = 993;
            ssl = true;          # 或 starttls = false
            # login = "your@email.com"  # 如果需要不同，通常省略
          };

          # 发送邮件（SMTP + OAuth2）
          message.send = {
            backend = {
              type = "smtp";
              host = "smtp-mail.office365.com";
              port = 587;
              ssl = false;           # 用 STARTTLS
              # starttls = true;     # 或者明确指定
            };

            # 关键：启用 OAuth2
            auth = {
              type = "oauth2";
              # 以下字段在第一次配置时会自动填充/交互式完成
              # client-id = "你的 Azure App Client ID";
              # client-secret = "你的 Client Secret";
              # auth-url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
              # token-url = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
              # redirect-uri = "http://localhost:8080";  # Himalaya 默认用这个
              # scope = "https://outlook.office.com/IMAP.AccessAsUser.All https://outlook.office.com/SMTP.Send offline_access";
              # refresh-token.keyring = "himalaya-outlook-refresh-token";  # 存储在系统 keyring
            };
          };

          # 可选：文件夹映射（Outlook 常见结构）
          folders = {
            inbox = "INBOX";
            sent = "Sent Items";
            draft = "Drafts";
            trash = "Deleted Items";
            # templates = "...";
          };

          # 可选：其他偏好
          # envelope.list = "threads";  # 线程视图
          # message.read = "pager";     # 用 less 或内置 pager 阅读
        };
      };
    };
  };

  # 强烈推荐：安装 keyring 支持（Himalaya 用它安全存储 refresh token）
  # Nixpkgs 的 himalaya 默认带 keyring 特征
  home.packages = with pkgs; [
    pass
  ];
}

