{ ... }: {
  programs.codex = {
    enable = true;

    settings = {
      model_provider = "micu";
      model = "gpt-5.4-mini";
      model_reasoning_effort = "high";
      disable_response_storage = true;

      model_providers = {
        micu = {
          name = "micu";
          base_url = "https://www.micuapi.ai/v1";
          wire_api = "responses";
          requires_openai_auth = true;
          model_context_window = 1000000;
          model_auto_compact_token_limit = 900000;
        };
      };
    };
  };
}

