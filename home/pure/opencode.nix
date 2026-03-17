{
  pkgs,
  ...
}: {
  programs.opencode = {
    enable = true;
    settings = {
      # Note: "$schema": "https://opencode.ai/config.json" is automatically added.
      provider = {
        openrouter = {
          npm = "@ai-sdk/openai-compatible";
          name = "OpenRouter";
          options = {
            baseURL = "https://openrouter.ai/api/v1";
            apiKey = "{env:OPENROUTER_API_KEY}";
          };
        };
      };
      permission = {
        "*" = "ask";
      };
    };
  };

  home.packages = with pkgs; [
    bun
  ];
}

