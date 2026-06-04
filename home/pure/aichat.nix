{ ...
}: {
  programs.aichat = {
    enable = true;

    settings = {
      model = "deepseek:deepseek-v4-flash";

      clients = [
        {
          type = "openai-compatible";
          name = "deepseek";
          api_base = "https://api.deepseek.com/v1";
          api_key = "\${DEEPSEEK_API_KEY}";
          models = map (name: {
            inherit name;
            max_input_tokens = 1048576;
            max_output_tokens = 16384;
            supports_function_calling = true;
          }) ["deepseek-v4-flash" "deepseek-v4-pro"];
        }
      ];

      stream = true;
      temperature = 0.7;
      compress_threshold = 100000;
    };
  };
}
