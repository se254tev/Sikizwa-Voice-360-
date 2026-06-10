import '../data/models/ai_chat_message.dart';

class AiChatState {
  final List<AiChatMessage> messages;
  final bool isSending;
  final bool isTyping;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.isTyping = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isSending,
    bool? isTyping,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isTyping: isTyping ?? this.isTyping,
      error: error,
    );
  }
}
