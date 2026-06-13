import '../data/models/ai_chat_request.dart';
import '../data/models/ai_chat_response.dart';
import '../repositories/ai_repository.dart';

class AiService {
  final AiRepository repository;

  const AiService({required this.repository});

  Future<AiChatResponse> sendMessage({required String message}) async {
    final request = AiChatRequest(message: message);
    return repository.sendChatMessage(request: request);
  }
}
