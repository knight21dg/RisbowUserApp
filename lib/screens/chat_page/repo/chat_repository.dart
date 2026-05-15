import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/headers.dart';
import 'package:hyper_local/screens/chat_page/model/chat_model.dart';

class ChatRepository {
  Future<ChatResponse> sendMessage(
    String message, {
    int? conversationId,
    String? model,
  }) async {
    final response = await http.post(
      Uri.parse(ApiRoutes.chatApi),
      headers: headers,
      body: jsonEncode({
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
        if (model != null) 'model': model,
      }),
    );

    final data = jsonDecode(response.body);
    return ChatResponse.fromJson(data);
  }

  Future<List<ChatConversation>> getConversations() async {
    final response = await http.get(
      Uri.parse(ApiRoutes.chatConversationsApi),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((conv) => ChatConversation.fromJson(conv))
            .toList();
      }
    }
    return [];
  }

  Future<ChatConversation?> getConversation(int id) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.chatConversationsApi}/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return ChatConversation.fromJson(data['data']);
      }
    }
    return null;
  }

  Future<bool> deleteConversation(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiRoutes.chatConversationsApi}/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  Future<List<ChatModel>> getModels() async {
    final response = await http.get(
      Uri.parse(ApiRoutes.chatModelsApi),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((model) => ChatModel.fromJson(model))
            .toList();
      }
    }
    return [];
  }
}
