class AiChatResponse {
  final String reply;
  final String? model;
  final DateTime createdAt;

  AiChatResponse({
    required this.reply,
    this.model,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      reply: (json['reply'] ?? json['response'] ?? '').toString(),
      model: json['model']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
