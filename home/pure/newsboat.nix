{
  ...
}: {
  programs.newsboat = {
    enable = true;
    urls = [
      {
        tags = [
          "AR"
          "arxiv"
        ];
        url = "https://rss.arxiv.org/rss/cs.AR";
      }
    ];
    extraConfig = ''
      browser "w3m %u"
      auto-reload yes
      reload-threads 5
      download-full-page yes
      notify-program "notify-send 'Newsboat' '%t - %T'"
    '';
  };
}

