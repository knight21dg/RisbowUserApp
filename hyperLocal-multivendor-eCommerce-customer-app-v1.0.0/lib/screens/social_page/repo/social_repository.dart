import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/headers.dart';
import 'package:hyper_local/screens/social_page/model/social_model.dart';

class SocialRepository {
  Future<List<StoryModel>> getStories({int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.storiesApi}?page=$page'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        if (data['data'] is List) {
          return (data['data'] as List).map((s) => StoryModel.fromJson(s)).toList();
        } else if (data['data']['data'] != null) {
          return (data['data']['data'] as List).map((s) => StoryModel.fromJson(s)).toList();
        }
      }
    }
    return [];
  }

  Future<List<StoryModel>> getSellerStories(int sellerId) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.storiesApi}/seller/$sellerId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List).map((s) => StoryModel.fromJson(s)).toList();
      }
    }
    return [];
  }

  Future<StoryModel?> viewStory(int storyId) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.storiesApi}/$storyId/view'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return StoryModel.fromJson(data['data']);
      }
    }
    return null;
  }

  Future<List<ReelModel>> getReels({bool featured = false, int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.reelsApi}?featured=$featured&page=$page'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        if (data['data'] is List) {
          return (data['data'] as List).map((r) => ReelModel.fromJson(r)).toList();
        } else if (data['data']['data'] != null) {
          return (data['data']['data'] as List).map((r) => ReelModel.fromJson(r)).toList();
        }
      }
    }
    return [];
  }

  Future<ReelModel?> getReel(int id) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.reelsApi}/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return ReelModel.fromJson(data['data']);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> likeReel(int reelId) async {
    final response = await http.post(
      Uri.parse('${ApiRoutes.reelsApi}/$reelId/like'),
      headers: headers,
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> commentReel(int reelId, String comment) async {
    final response = await http.post(
      Uri.parse('${ApiRoutes.reelsApi}/$reelId/comments'),
      headers: headers,
      body: jsonEncode({'comment': comment}),
    );

    return jsonDecode(response.body);
  }

  Future<List<ReelCommentModel>> getReelComments(int reelId) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.reelsApi}/$reelId/comments'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        if (data['data'] is List) {
          return (data['data'] as List).map((c) => ReelCommentModel.fromJson(c)).toList();
        } else if (data['data']['data'] != null) {
          return (data['data']['data'] as List).map((c) => ReelCommentModel.fromJson(c)).toList();
        }
      }
    }
    return [];
  }
}
