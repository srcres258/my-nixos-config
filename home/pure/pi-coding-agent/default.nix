{ ... }:

{
  programs.pi-coding-agent = {
    enable = true;

    models = {
      providers.openai-codex = {
        models = [
          {
            id = "gpt-5.6-sol";
            name = "GPT-5.6 Sol";
            api = "openai-codex-responses";
            reasoning = true;
            input = [ "text" "image" ];
            contextWindow = 272000;
            maxTokens = 32000;
          }
          {
            id = "gpt-5.6-terra";
            name = "GPT-5.6 Terra";
            api = "openai-codex-responses";
            reasoning = true;
            input = [ "text" "image" ];
            contextWindow = 272000;
            maxTokens = 32000;
          }
        ];
      };
    };
  };
}

