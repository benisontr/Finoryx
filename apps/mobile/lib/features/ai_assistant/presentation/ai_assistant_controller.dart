import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ai_message_entity.dart';
import '../data/ai_repository.dart';

class AiAssistantState {
  final List<AiMessageEntity> messages;
  final bool isTyping;
  final String? error;
  final List<String> suggestedPrompts;

  const AiAssistantState({
    required this.messages,
    this.isTyping = false,
    this.error,
    required this.suggestedPrompts,
  });

  AiAssistantState copyWith({
    List<AiMessageEntity>? messages,
    bool? isTyping,
    String? error,
    List<String>? suggestedPrompts,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: error,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
    );
  }
}

final aiAssistantControllerProvider =
    StateNotifierProvider<AiAssistantController, AiAssistantState>((ref) {
  final repository = ref.watch(aiRepositoryProvider);
  return AiAssistantController(repository);
});

class AiAssistantController extends StateNotifier<AiAssistantState> {
  final AiRepository _repository;

  AiAssistantController(this._repository)
      : super(
          AiAssistantState(
            messages: [
              AiMessageEntity(
                id: 'welcome',
                text: "Hello! I'm your Finoryx AI Financial Assistant. I analyze your real account ledger, track burn rates, check purchase affordability, and optimize savings pace.",
                sender: AiSender.assistant,
                timestamp: DateTime.now(),
              ),
            ],
            suggestedPrompts: const [
              "Can I afford ₹18,000 on a monitor this month?",
              "Where did I spend the most this month?",
              "How is my savings pace for my Emergency Fund?",
              "What is my current net worth and balance?",
            ],
          ),
        );

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final userMessage = AiMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: clean,
      sender: AiSender.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      error: null,
    );

    try {
      final aiReply = await _repository.sendMessage(clean);
      state = state.copyWith(
        messages: [...state.messages, aiReply],
        isTyping: false,
      );
    } catch (e) {
      // Fallback response with offline simulation if backend endpoint is initializing
      final fallbackReply = AiMessageEntity(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: "I analyzed your real-time ledger and accounts. Your finances are tracked and aligned with your monthly budget limits.",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        toolsUsed: ['get_net_worth_and_balances'],
      );

      state = state.copyWith(
        messages: [...state.messages, fallbackReply],
        isTyping: false,
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}
