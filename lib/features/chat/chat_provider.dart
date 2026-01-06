import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

/// Chat message model.
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Usage statistics from LLM.
class ChatUsageStats {
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double cost;
  final int durationMs;

  const ChatUsageStats({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
    this.cost = 0.0,
    this.durationMs = 0,
  });

  ChatUsageStats operator +(ChatUsageStats other) {
    return ChatUsageStats(
      inputTokens: inputTokens + other.inputTokens,
      outputTokens: outputTokens + other.outputTokens,
      totalTokens: totalTokens + other.totalTokens,
      cost: cost + other.cost,
      durationMs: durationMs + other.durationMs,
    );
  }

  factory ChatUsageStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChatUsageStats();
    return ChatUsageStats(
      inputTokens: json['input_tokens'] ?? 0,
      outputTokens: json['output_tokens'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
      cost: (json['cost'] ?? 0.0).toDouble(),
      durationMs: json['duration_ms'] ?? 0,
    );
  }
}

/// Chat state.
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final ChatUsageStats totalUsage;
  final int requestCount;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.totalUsage = const ChatUsageStats(),
    this.requestCount = 0,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    ChatUsageStats? totalUsage,
    int? requestCount,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalUsage: totalUsage ?? this.totalUsage,
      requestCount: requestCount ?? this.requestCount,
    );
  }
}

/// Chat notifier for managing chat state.
class ChatNotifier extends Notifier<ChatState> {
  static const String _model = 'gpt-5.2';

  @override
  ChatState build() => const ChatState();

  /// Send a message to the chat API.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(role: 'user', content: text.trim());

    // Add user message and set loading
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final dio = ref.read(dioProvider);

      // Build history from previous messages (limit to last 10)
      final history = state.messages
          .take(state.messages.length - 1) // Exclude the message we just added
          .map((m) => m.toJson())
          .toList();

      // Keep only last 10 messages for context
      final limitedHistory = history.length > 10
          ? history.sublist(history.length - 10)
          : history;

      final response = await dio.post(
        '/chat',
        data: {
          'message': text.trim(),
          'model': _model,
          'history': limitedHistory,
        },
      );

      final responseText = response.data['response'] as String? ?? 'Нет ответа';

      // Extract usage stats
      final usage = ChatUsageStats.fromJson(
        response.data['usage'] as Map<String, dynamic>?,
      );

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: responseText,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
        totalUsage: state.totalUsage + usage,
        requestCount: state.requestCount + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ошибка: $e');

      // Add error message as assistant response
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: 'Произошла ошибка при отправке сообщения. Попробуйте еще раз.',
      );

      state = state.copyWith(messages: [...state.messages, errorMessage]);
    }
  }

  /// Clear chat history.
  void clearHistory() {
    state = const ChatState();
  }

  /// Reset only usage stats (keep messages).
  void resetStats() {
    state = state.copyWith(totalUsage: const ChatUsageStats(), requestCount: 0);
  }
}

/// Chat provider.
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
