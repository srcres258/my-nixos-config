{
  pkgs,
  ...
}: let
  passPkg = pkgs.pass;
in {
  # 全局启用 Himalaya（安装二进制 + 基本设置）
  programs.himalaya = {
    enable = true;
    package = pkgs.himalaya.override {
      withFeatures = [ "oauth2" "keyring" ];
    };
  };

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
        settings = let
          mailAddr = "srcres258@furdevs.cn";
          auth = {
            type = "oauth2";
            method = "xoauth2";
            client-id = "8a1b3af2-1641-4ef0-b0fc-e68862579fde";
            client-secret.keyring = "outlook-oauth2-client-secret";
            access-token.keyring = "outlook-oauth2-access-token";
            refresh-token.keyring = "outlook-oauth2-refresh-token";
            auth-url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize";
            token-url = "https://login.microsoftonline.com/common/oauth2/v2.0/token";
            pkce = true;
            scopes = [
              "https://outlook.office.com/IMAP.AccessAsUser.All"
              "https://outlook.office.com/SMTP.Send"
            ];
          };
        in {
          email = mailAddr;

          backend = {
            type = "imap";
            host = "outlook.office365.com";
            port = 993;
            encryption.type = "tls";
            login = mailAddr;
            inherit auth;
          };

          message.send.backend = {
            type = "smtp";
            host = "smtp-mail.outlook.com";
            port = 587;
            encryption.type = "start-tls";
            login = mailAddr;
            inherit auth;
          };
        };
      };
    };
  };

  # 强烈推荐：安装 keyring 支持（Himalaya 用它安全存储 refresh token）
  # Nixpkgs 的 himalaya 默认带 keyring 特征
  home.packages = [ passPkg ];
}

