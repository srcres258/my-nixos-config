{
  config,
  pkgs,
  ...
}: {
  programs.neomutt = {
    enable = true;

    vimKeys = true;

    sidebar = {
      enable = true;
      shortPath = true;
      width = 28;
    };

    extraConfig = ''
      set timeout = 10
      set beep = no
      set pager_index_lines = 8
      set sort = 'threads'
      set sort_aux = 'last-date-received'

      color index brightyellow default "~N"
      color status cyan default ""
    '';

    sourcePrimaryAccount = true;
  };

  accounts.email.accounts = let
    mailAddr = "srcres258@furdevs.cn";
  in {
    personal = {
      address = mailAddr;
      realName = "Haowen Hu";
      userName = mailAddr;
      primary = true;

      mbsync.enable = true;
      imap = {
        host = "outlook.office365.com";
        port = 993;
        tls.enable = true;
      };
      passwordCommand = "${pkgs.pass}/bin/pass email/personal";

      msmtp.enable = true;
      smtp = {
        host = "smtp-mail.outlook.com";
        port = 587;
        tls.enable = true;
      };

      neomutt = {
        enable = true;

        mailboxName = "=== Inbox ===";
        extraMailboxes = [
          { mailbox = "[Gmail]/Sent Mail";   name = "Sent";   }
          { mailbox = "[Gmail]/Trash";       name = "Trash";  }
          { mailbox = "[Gmail]/Drafts";      name = "Drafts"; }
        ];
      };
    };
  };

  programs = {
    msmtp.enable = true;
    mbsync.enable = true;
  };

  home.packages = with pkgs; [
    pass
    w3m
  ];
}

