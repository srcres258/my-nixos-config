{
  ...
}: {
  programs.newsboat = {
    enable = true;
    urls = [
      {
        tags = [
          "AI"
          "arxiv"
        ];
        url = "https://rss.arxiv.org/rss/cs.AI";
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

