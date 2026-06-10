class AiChatRequest {
  final String message;
  final Map<String, dynamic> context;

  const AiChatRequest({
    required this.message,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'context': context,
      };
}
