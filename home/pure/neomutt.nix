{ ... }:

{
  programs.neomutt = {
    enable = true;

    vimKeys = true;

    extraConfig = ''
      set sort = threads
      set sort_aux = reverse-last-date-received
      set pager_index_lines = 10
    '';
  };

  accounts.email.accounts.gmail = {
    primary = true;

    address = "src.res.211@gmail.com";
    userName = "src.res.211@gmail.com";
    realName = "Haowen Hu";

    flavor = "gmail.com";

    neomutt = {
      enable = true;
      mailboxType = "imap";
    };
  };
}

