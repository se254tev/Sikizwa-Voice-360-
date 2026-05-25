import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../src/providers/app_providers.dart';
import '../data/models/ai_chat_message.dart';
import '../repositories/ai_repository.dart';
import '../services/ai_service.dart';
import 'ai_chat_notifier.dart';
import 'ai_chat_state.dart';
import 'typing_indicator.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final api = ref.read(aiApiServiceProvider);
  return AiRepository(api: api);
});

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final aiService = AiService(repository: ref.read(aiRepositoryProvider));
  return AiChatNotifier(aiService);
});

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final notifier = ref.read(aiChatProvider.notifier);
    notifier.sendMessage(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);
    final notifier = ref.read(aiChatProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sikizwa Care Companion'),
        actions: [
          if (state.error != null)
            TextButton(
              onPressed: notifier.retryLast,
              child: const Text('Retry'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      reverse: true,
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages.reversed.toList()[index];
                        final isUser = message.sender.name == 'user';
                        return _ChatBubble(message: message, isUser: isUser);
                      },
                    ),
            ),
            if (state.isTyping) const Padding(padding: EdgeInsets.only(bottom: 12), child: TypingIndicator()),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Share what you are feeling...',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: state.isSending ? null : _send,
                    icon: state.isSending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final prompts = ['I need support today', 'Help me through a tough day', 'What should I do when I feel anxious'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology_alt_rounded, size: 48, color: Colors.deepPurple),
          const SizedBox(height: 16),
          const Text(
            'Talk safely with Sikizwa Care',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a gentle prompt or start with what you are feeling right now.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: prompts
                .map(
                  (prompt) => ActionChip(
                    label: Text(prompt),
                    onPressed: () {
                      _controller.text = prompt;
                      _send();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isUser});

  final AiChatMessage message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? Colors.deepPurple : Colors.grey.shade100;
    final textColor = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Card(
          color: bubbleColor,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(color: textColor, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 11, color: isUser ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
