enum AiChatMessageSender { user, assistant }

class AiChatMessage {
  final String id;
  final String text;
  final AiChatMessageSender sender;
  final DateTime timestamp;
  final bool isRetryable;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isRetryable = false,
  });

  AiChatMessage copyWith({
    String? text,
    bool? isRetryable,
  }) {
    return AiChatMessage(
      id: id,
      text: text ?? this.text,
      sender: sender,
      timestamp: timestamp,
      isRetryable: isRetryable ?? this.isRetryable,
    );
  }
}
