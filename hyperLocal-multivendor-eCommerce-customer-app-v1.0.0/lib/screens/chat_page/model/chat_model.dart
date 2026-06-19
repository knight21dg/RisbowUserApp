class ChatMessage {
  final int? id;
  final String role;
  final String message;
  final String? response;
  final DateTime? createdAt;

  ChatMessage({
    this.id,
    required this.role,
    required this.message,
    this.response,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'] ?? 'user',
      message: json['message'] ?? '',
      response: json['response'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'message': message,
      'response': response,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ChatConversation {
  final int id;
  final String title;
  final String? model;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.title,
    this.model,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'New Conversation',
      model: json['model'],
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((m) => ChatMessage.fromJson(m))
              .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}

class ChatResponse {
  final bool success;
  final int? conversationId;
  final String? response;
  final String? message;
  final Map<String, dynamic>? usage;

  ChatResponse({
    required this.success,
    this.conversationId,
    this.response,
    this.message,
    this.usage,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      success: json['success'] ?? false,
      conversationId: json['data']?['conversation_id'],
      response: json['data']?['response'],
      message: json['message'],
      usage: json['data']?['usage'],
    );
  }
}

class ChatModel {
  final String id;
  final String name;

  ChatModel({
    required this.id,
    required this.name,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
