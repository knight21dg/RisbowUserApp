import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/headers.dart';
import 'package:hyper_local/screens/chat_page/model/bow_model.dart';
import 'package:hyper_local/services/location/location_service.dart';

class BowRepository {
  List<Map<String, dynamic>>? _cachedProducts;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  Future<List<Map<String, dynamic>>> _getProductsForAI() async {
    final now = DateTime.now();
    if (_cachedProducts != null && 
        _lastFetchTime != null && 
        now.difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedProducts!;
    }

    try {
      final coords = LocationService.getCoordinates();
      final allProducts = <Map<String, dynamic>>[];
      
      // Fetch ALL products using pagination
      int page = 1;
      bool hasMore = true;
      
      while (hasMore) {
        final response = await http.get(
          Uri.parse(
            '${ApiRoutes.categoryProductApi}?latitude=${coords['latitude']}&longitude=${coords['longitude']}&per_page=100&page=$page'
          ),
          headers: headers,
        ).timeout(const Duration(seconds: 30));

         if (response.statusCode == 200) {
           final data = jsonDecode(response.body);
           if (data['success'] == true && data['data'] != null) {
             final raw = data['data'];
             List<dynamic> products;
             if (raw is List) {
               products = raw;
             } else if (raw is Map) {
               // Some APIs wrap in {data: {...}}; try to find nested list
               final nested = raw['data'];
               if (nested is List) {
                 products = nested;
               } else {
                 products = [];
               }
             } else {
               products = [];
             }
             if (products.isNotEmpty) {
               allProducts.addAll(products.map((p) => _formatProductForAI(p as Map<String, dynamic>)));
               page++;
               hasMore = products.length >= 100;
             } else {
               hasMore = false;
             }
           } else {
             hasMore = false;
           }
         } else {
           hasMore = false;
         }
      }
      
      _cachedProducts = allProducts;
      _lastFetchTime = now;
      print('BOW: Fetched ${_cachedProducts!.length} products for AI');
      return _cachedProducts!;
    } catch (e) {
      print('Error fetching products for AI: $e');
    }
    return [];
  }

  Map<String, dynamic> _formatProductForAI(Map<String, dynamic> product) {
    return {
      'id': product['id'],
      'name': product['name'] ?? '',
      'slug': product['slug'] ?? '',
      'price': product['price'] ?? 0,
      'special_price': product['special_price'] ?? product['price'] ?? 0,
      'discount': product['discount'] ?? 0,
      'image': product['image'] ?? '',
      'category': product['category_name'] ?? product['category'] ?? '',
      'store': product['store_name'] ?? '',
      'rating': product['rating'] ?? 0,
      'review_count': product['review_count'] ?? 0,
      'in_stock': product['stock'] ?? true,
      'description': product['description'] ?? '',
    };
  }

  Future<BowMessage> sendMessage({
    required String message,
    String? imageUrl,
    String? voiceData,
    List<Map<String, dynamic>>? context,
    bool includeProducts = true,
  }) async {
    List<Map<String, dynamic>> enrichedContext = context ?? [];
    
    if (includeProducts) {
      final products = await _getProductsForAI();
      if (products.isNotEmpty) {
        enrichedContext = [
          ...context ?? [],
          {
            'type': 'products',
            'data': products,
            'description': 'Available products for recommendations and comparisons',
          },
        ];
      }
    }

    print('BOW CHAT REQUEST: ${Uri.parse(ApiRoutes.bowChatApi)}');
    print('BOW CHAT CONTEXT PRODUCTS COUNT: ${enrichedContext.where((c) => c['type'] == 'products').isNotEmpty ? (enrichedContext.firstWhere((c) => c['type'] == 'products', orElse: () => {})['data'] as List?)?.length ?? 0 : 0}');

    final startTime = DateTime.now();
    try {
      final response = await http.post(
        Uri.parse(ApiRoutes.bowChatApi),
        headers: headers,
        body: jsonEncode({
          'message': message,
          'image_url': imageUrl,
          'voice_data': voiceData,
          'context': enrichedContext,
          'include_products': includeProducts,
        }),
      ).timeout(const Duration(seconds: 90));

      final duration = DateTime.now().difference(startTime);
      print('BOW CHAT RESPONSE (${duration.inMilliseconds}ms): ${response.statusCode} - ${response.body}');

      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['data'] != null) {
        return BowMessage.fromJson(data['data']);
      }
      
      return BowMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: data['message'] ?? 'Sorry, I could not process your request.',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('BOW CHAT ERROR: $e');
      return BowMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: 'Connection error: $e',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<BowConfig> getConfig() async {
    final response = await http.get(
      Uri.parse(ApiRoutes.bowConfigApi),
      headers: headers,
    );

    final data = jsonDecode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      return BowConfig.fromJson(data['data']);
    }
    
    return BowConfig(
      apiUrl: '',
      apiKey: '',
      model: 'openai/gpt-4o-mini',
    );
  }

  Future<List<BowSuggestion>> getSuggestions() async {
    final response = await http.get(
      Uri.parse(ApiRoutes.bowSuggestionsApi),
      headers: headers,
    );

    final data = jsonDecode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> list = data['data'];
      return list.map((e) => BowSuggestion(
        id: e['id']?.toString() ?? '',
        text: e['text'] ?? '',
        icon: e['icon'] ?? '💡',
        type: e['type'] ?? 'general',
      )).toList();
    }
    
    return BowSuggestion.getDefaultSuggestions();
  }

  Future<Map<String, dynamic>> executeAction(BowAction action) async {
    final response = await http.post(
      Uri.parse(ApiRoutes.bowExecuteActionApi),
      headers: headers,
      body: jsonEncode(action.toJson()),
    );

    return jsonDecode(response.body);
  }

  Future<String> textToSpeech(String text, String languageCode) async {
    final response = await http.post(
      Uri.parse(ApiRoutes.bowTextToSpeechApi),
      headers: headers,
      body: jsonEncode({
        'text': text,
        'language': languageCode,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      return data['data']['audio_url'] ?? '';
    }
    
    return '';
  }

  Future<String> speechToText(String audioPath) async {
    final response = await http.post(
      Uri.parse(ApiRoutes.bowSpeechToTextApi),
      headers: headers,
      body: jsonEncode({'audio_path': audioPath}),
    );

    final data = jsonDecode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      return data['data']['text'] ?? '';
    }
    
    return '';
  }

  Future<List<BowMessage>> getConversationHistory(int conversationId) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.bowConversationHistoryApi}?conversation_id=$conversationId'),
      headers: headers,
    );

    final data = jsonDecode(response.body);
    
    if (data['success'] == true && data['data'] != null) {
      final List<dynamic> list = data['data'];
      return list.map((e) => BowMessage.fromJson(e)).toList();
    }
    
    return [];
  }

  Future<void> clearHistory() async {
    await http.post(
      Uri.parse(ApiRoutes.bowClearHistoryApi),
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> addToCart(List<int> productIds, List<int> quantities) async {
    return await executeAction(BowAction(
      type: 'add_to_cart',
      data: {
        'product_ids': productIds,
        'quantities': quantities,
      },
    ));
  }

  Future<Map<String, dynamic>> searchProducts(String query) async {
    return await executeAction(BowAction(
      type: 'search',
      data: {'query': query},
    ));
  }

  Future<Map<String, dynamic>> applyCoupon(String couponCode) async {
    return await executeAction(BowAction(
      type: 'apply_coupon',
      data: {'code': couponCode},
    ));
  }

  Future<Map<String, dynamic>> getOffers() async {
    return await executeAction(BowAction(
      type: 'show_offers',
      data: {},
    ));
  }

  Future<Map<String, dynamic>> getRooms() async {
    return await executeAction(BowAction(
      type: 'show_rooms',
      data: {},
    ));
  }

  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    return await executeAction(BowAction(
      type: 'track_order',
      data: {'order_id': orderId},
    ));
  }

  void clearProductCache() {
    _cachedProducts = null;
    _lastFetchTime = null;
  }

  Future<List<Map<String, dynamic>>> searchProductsForAI(String query) async {
    final allProducts = await _getProductsForAI();
    if (query.isEmpty) return allProducts;
    
    final queryLower = query.toLowerCase();
    return allProducts.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();
      final store = (p['store'] ?? '').toString().toLowerCase();
      return name.contains(queryLower) || 
             category.contains(queryLower) || 
             store.contains(queryLower);
    }).toList();
  }
}