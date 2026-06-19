import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/chat_page/model/bow_model.dart';
import 'package:hyper_local/screens/chat_page/repo/bow_repository.dart';

abstract class BowEvent {}

class BowInitialize extends BowEvent {}

class BowSendMessage extends BowEvent {
  final String message;
  final String? imageUrl;
  final String? voiceData;

  BowSendMessage({
    required this.message,
    this.imageUrl,
    this.voiceData,
  });
}

class BowSendSuggestion extends BowEvent {
  final BowSuggestion suggestion;

  BowSendSuggestion({required this.suggestion});
}

class BowExecuteAction extends BowEvent {
  final BowAction action;

  BowExecuteAction({required this.action});
}

class BowTextToSpeech extends BowEvent {
  final String text;
  final String languageCode;

  BowTextToSpeech({required this.text, required this.languageCode});
}

class BowSpeechToText extends BowEvent {
  final String audioPath;

  BowSpeechToText({required this.audioPath});
}

class BowClearHistory extends BowEvent {}

class BowLoadHistory extends BowEvent {
  final int conversationId;

  BowLoadHistory({required this.conversationId});
}

class BowToggleExpanded extends BowEvent {}

abstract class BowState {}

class BowInitial extends BowState {}

class BowLoading extends BowState {}

class BowReady extends BowState {
  final List<BowMessage> messages;
  final List<BowSuggestion> suggestions;
  final bool isExpanded;
  final bool isSpeaking;
  final bool isListening;
  final String? error;

  BowReady({
    this.messages = const [],
    this.suggestions = const [],
    this.isExpanded = false,
    this.isSpeaking = false,
    this.isListening = false,
    this.error,
  });

  BowReady copyWith({
    List<BowMessage>? messages,
    List<BowSuggestion>? suggestions,
    bool? isExpanded,
    bool? isSpeaking,
    bool? isListening,
    String? error,
  }) {
    return BowReady(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isExpanded: isExpanded ?? this.isExpanded,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isListening: isListening ?? this.isListening,
      error: error,
    );
  }
}

class BowError extends BowState {
  final String message;

  BowError({required this.message});
}

class BowBloc extends Bloc<BowEvent, BowState> {
  final BowRepository _repository = BowRepository();

  BowBloc() : super(BowInitial()) {
    on<BowInitialize>(_onInitialize);
    on<BowSendMessage>(_onSendMessage);
    on<BowSendSuggestion>(_onSendSuggestion);
    on<BowExecuteAction>(_onExecuteAction);
    on<BowTextToSpeech>(_onTextToSpeech);
    on<BowSpeechToText>(_onSpeechToText);
    on<BowClearHistory>(_onClearHistory);
    on<BowLoadHistory>(_onLoadHistory);
    on<BowToggleExpanded>(_onToggleExpanded);
  }

  Future<void> _onInitialize(BowInitialize event, Emitter<BowState> emit) async {
    emit(BowLoading());
    print('[BOW_MOBILE] Initializing Bow assistant...');
    try {
      final suggestions = await _repository.getSuggestions();
      print('[BOW_MOBILE] Initialization successful. Suggestions loaded: ${suggestions.length}');
      emit(BowReady(suggestions: suggestions));
    } catch (e) {
      print('[BOW_MOBILE] Initialization failed: $e');
      emit(BowReady(suggestions: BowSuggestion.getDefaultSuggestions()));
    }
  }

  Future<void> _onSendMessage(BowSendMessage event, Emitter<BowState> emit) async {
    final currentState = state;
    if (currentState is! BowReady) return;

    final userMessage = BowMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: event.message,
      type: MessageType.text,
      createdAt: DateTime.now(),
    );

    final loadingMessage = BowMessage(
      id: 'loading',
      role: 'assistant',
      content: '',
      type: MessageType.text,
      createdAt: DateTime.now(),
    );

    print('[BOW_MOBILE] Sending message: ${event.message}');
    emit(currentState.copyWith(
      messages: [...currentState.messages, userMessage, loadingMessage],
    ));

    try {
      final response = await _repository.sendMessage(
        message: event.message,
        imageUrl: event.imageUrl,
        voiceData: event.voiceData,
        includeProducts: true,
      );

      print('[BOW_MOBILE] Response received: ${response.content.substring(0, response.content.length > 50 ? 50 : response.content.length)}...');

      // Create new message list with user message and response
      final List<BowMessage> newMessages = [
        ...currentState.messages.where((m) => m.id != 'loading'),
        userMessage,
        response,
      ];

      // Local intent recognition for navigation
      final lowerMessage = event.message.toLowerCase();
      if (lowerMessage.contains('open') && (lowerMessage.contains('room') || lowerMessage.contains('rooms'))) {
        print('[BOW_MOBILE] Local navigation intent detected: room page');
        if (response.action == null) {
          // Manually inject a navigation action if none exists
          final modifiedResponse = BowMessage(
            id: response.id,
            role: response.role,
            content: response.content,
            type: response.type,
            createdAt: response.createdAt,
            intent: response.intent,
            suggestedProducts: response.suggestedProducts,
            action: BowAction(type: 'navigate', data: {'path': '/rooms'}),
          );
          emit(currentState.copyWith(messages: [
            ...currentState.messages.where((m) => m.id != 'loading'),
            userMessage,
            modifiedResponse,
          ]));
          
          // Trigger the action execution
          add(BowExecuteAction(action: modifiedResponse.action!));
          return;
        }
      }

      emit(currentState.copyWith(messages: newMessages));

      // Handle actions - add to cart, view product, etc.
      if (response.action != null) {
        print('[BOW_MOBILE] Action detected in response: ${response.action!.type}');
        
        // Execute action directly in bloc
        if (response.action!.type == 'add_to_cart' && response.action!.data != null) {
          final productId = response.action!.data!['product_id'];
          final quantity = response.action!.data!['quantity'] ?? 1;
          if (productId != null) {
            print('[BOW_MOBILE] Adding product to cart: $productId, qty: $quantity');
            // Add to cart - this would need CartBloc
          }
        }
        
        add(BowExecuteAction(action: response.action!));
      }
    } catch (e) {
      print('[BOW_MOBILE] Error sending message: $e');
      final errorMessages = currentState.messages
          .where((m) => m.id != 'loading')
          .toList()
        ..add(userMessage);

      emit(currentState.copyWith(
        messages: errorMessages,
        error: 'Failed to send message: $e',
      ));
    }
  }

  Future<void> _onSendSuggestion(BowSendSuggestion event, Emitter<BowState> emit) async {
    add(BowSendMessage(message: event.suggestion.text));
  }

  Future<void> _onExecuteAction(BowExecuteAction event, Emitter<BowState> emit) async {
    print('[BOW_MOBILE] Executing action: ${event.action.type}');
    try {
      final result = await _repository.executeAction(event.action);
      print('[BOW_MOBILE] Action execution result: ${result['success']}');
    } catch (e) {
      print('[BOW_MOBILE] Action execution failed: $e');
      // Silent fail for actions
    }
  }

  Future<void> _onTextToSpeech(BowTextToSpeech event, Emitter<BowState> emit) async {
    final currentState = state;
    if (currentState is! BowReady) return;

    emit(currentState.copyWith(isSpeaking: true));

    try {
      final audioUrl = await _repository.textToSpeech(event.text, event.languageCode);
      // Play audio URL
      // For now, just update state
      emit(currentState.copyWith(isSpeaking: false));
    } catch (e) {
      emit(currentState.copyWith(isSpeaking: false));
    }
  }

  Future<void> _onSpeechToText(BowSpeechToText event, Emitter<BowState> emit) async {
    final currentState = state;
    if (currentState is! BowReady) return;

    emit(currentState.copyWith(isListening: true));

    try {
      final text = await _repository.speechToText(event.audioPath);
      if (text.isNotEmpty) {
        add(BowSendMessage(message: text));
      }
      emit(currentState.copyWith(isListening: false));
    } catch (e) {
      emit(currentState.copyWith(isListening: false));
    }
  }

  Future<void> _onClearHistory(BowClearHistory event, Emitter<BowState> emit) async {
    final currentState = state;
    if (currentState is! BowReady) return;

    await _repository.clearHistory();
    emit(currentState.copyWith(messages: []));
  }

  Future<void> _onLoadHistory(BowLoadHistory event, Emitter<BowState> emit) async {
    final currentState = state;
    if (currentState is! BowReady) return;

    try {
      final messages = await _repository.getConversationHistory(event.conversationId);
      emit(currentState.copyWith(messages: messages));
    } catch (e) {
      print('[BOW_MOBILE] Failed to load conversation history: $e');
    }
  }

  void _onToggleExpanded(BowToggleExpanded event, Emitter<BowState> emit) {
    final currentState = state;
    if (currentState is! BowReady) return;

    emit(currentState.copyWith(isExpanded: !currentState.isExpanded));
  }
}