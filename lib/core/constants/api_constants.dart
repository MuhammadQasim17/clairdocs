class ApiConstants {
  ApiConstants._();

  static const String defaultGeminiModel = 'gemini-3.8-flash';
  static const String fallbackGeminiModel = 'gemini-3.5-flash-lite';
  static const List<String> geminiModelFallbackChain = [
    defaultGeminiModel,
    fallbackGeminiModel,
  ];
  static const String defaultGeminiModelDisplayName = 'Gemini 3.8 Flash';
  static const String defaultGeminiModelShortBadge = 'GEMINI 3.8';
  static const String proGeminiModel = 'gemini-3.8-pro';

  // Groq Engine (20B ultra-fast primary for audits -> 120B fallback)
  static const String groqEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'openai/gpt-oss-20b';
  static const String groqFallbackModel = 'openai/gpt-oss-120b';
  static const List<String> groqModelFallbackChain = [
    groqModel,
    groqFallbackModel,
  ];
  static const List<String> groqDraftModelChain = [
    groqFallbackModel,
    groqModel,
  ];
  static const String groqEngineLabel = 'Engine: GPT-OSS 20B (Groq)';
  static const String groqFallbackEngineLabel = 'Engine: GPT-OSS 120B (Groq)';
  static const int groqAuditMaxTokens = 1500;
  static const int groqMaxTokens = 4096;

  static const Duration geminiAuditTimeout = Duration(seconds: 8);
  static const Duration geminiSlowStatusDelay = Duration(seconds: 4);
  static const Duration groqAuditTimeout = Duration(seconds: 10);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const int maxPromptDocumentChars = 12000;
  static const int maxRetryAttempts = 2;
  static const Duration baseRetryBackoff = Duration(milliseconds: 1500);
}
