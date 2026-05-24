import '../../../src/core/errors.dart';
import '../../../src/services/api_service.dart';
import '../data/models/ai_chat_request.dart';
import '../data/models/ai_chat_response.dart';

class AiRepository {
  const AiRepository({required this.api});

  final ApiService api;

  static const int _maxMessageLength = 4000;

  Future<AiChatResponse> sendChatMessage({required AiChatRequest request}) async {
    final message = request.message.trim();
    if (message.isEmpty) {
      throw ApiException(
        error: const ApiError(
          statusCode: 400,
          message: 'Please enter a message before sending.',
        ),
      );
    }

    if (message.length > _maxMessageLength) {
      throw ApiException(
        error: const ApiError(
          statusCode: 400,
          message: 'Your message is too long. Please shorten it and try again.',
        ),
      );
    }

    final response = await api.post(
      '/chat',
      data: {
        'message': message,
        'context': request.context,
      },
      timeoutMs: 30000,
    );

    final payload = response is Map<String, dynamic>
        ? response
        : (response is Map ? Map<String, dynamic>.from(response) : <String, dynamic>{});

    if (payload.isEmpty) {
      throw ApiException(
        error: const ApiError(
          statusCode: 502,
          message: 'The AI service returned an empty response. Please try again.',
        ),
      );
    }

    final reply = payload['reply'] ?? payload['response'];
    if (reply is! String || reply.trim().isEmpty) {
      throw ApiException(
        error: const ApiError(
          statusCode: 502,
          message: 'The AI service returned an invalid response. Please try again.',
        ),
      );
    }

    return AiChatResponse.fromJson({'reply': reply});
  }
}
