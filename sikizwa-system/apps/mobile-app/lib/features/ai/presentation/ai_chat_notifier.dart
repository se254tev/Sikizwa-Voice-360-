import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../../src/core/errors.dart';
import '../data/models/ai_chat_message.dart';
import '../services/ai_service.dart';
import 'ai_chat_state.dart';

class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier(this._service) : super(const AiChatState());

  final AiService _service;
  final _uuid = const Uuid();

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final userMessage = AiChatMessage(
      id: _uuid.v4(),
      text: trimmed,
      sender: AiChatMessageSender.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      isTyping: true,
      error: null,
    );

    try {
      final response = await _service.sendMessage(message: trimmed);
      final assistantMessage = AiChatMessage(
        id: _uuid.v4(),
        text: response.reply,
        sender: AiChatMessageSender.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
        isTyping: false,
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        isTyping: false,
        error: formatError(error),
      );
    }
  }

  Future<void> retryLast() async {
    AiChatMessage? lastUserMessage;

    for (final message in state.messages.reversed) {
      if (message.sender == AiChatMessageSender.user) {
        lastUserMessage = message;
        break;
      }
    }

    if (lastUserMessage == null) {
      return;
    }

    await sendMessage(lastUserMessage.text);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
