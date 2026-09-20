import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/finoryx_pill.dart';
import '../domain/ai_message_entity.dart';
import 'ai_assistant_controller.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;

  const AiAssistantScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(aiAssistantControllerProvider.notifier).sendMessage(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;
    ref.read(aiAssistantControllerProvider.notifier).sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = ref.watch(userCurrencySymbolProvider);
    final state = ref.watch(aiAssistantControllerProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.aiContainerDark : AppColors.aiContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.aiAccent),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finoryx AI Copilot',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Connected to Ledger',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Suggested Prompt Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: state.suggestedPrompts.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final prompt = state.suggestedPrompts[idx];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFD8B4FE) : AppColors.aiAccent,
                    ),
                  ),
                  backgroundColor: isDark ? AppColors.aiContainerDark : AppColors.aiContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF6B21A8) : const Color(0xFFDDD6FE),
                      width: 0.8,
                    ),
                  ),
                  onPressed: () => _handleSend(prompt),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Message Stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final msg = state.messages[index];
                return _buildMessageBubble(msg, isDark, currencySymbol);
              },
            ),
          ),

          // Typing Indicator
          if (state.isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.aiAccent)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Finoryx AI is computing financial intelligence...',
                    style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  ),
                ],
              ),
            ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask about affordability, budgets, goals...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: _handleSend,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.aiAccent,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      onPressed: () => _handleSend(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiMessageEntity msg, bool isDark, String currencySymbol) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0, left: 48.0),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0, right: 32.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(AppRadius.lg),
                  bottomRight: Radius.circular(AppRadius.lg),
                ),
                border: Border.all(
                  color: isDark ? const Color(0xFF4C1D95) : const Color(0xFFE9D5FF),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (msg.structuredInsight != null) ...[
                    const SizedBox(height: 12),
                    _buildStructuredInsightWidget(msg.structuredInsight!, isDark, currencySymbol),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredInsightWidget(
    AiStructuredInsightEntity insight,
    bool isDark,
    String currencySymbol,
  ) {
    if (insight.affordability != null) {
      final aff = insight.affordability!;
      FinoryxPillVariant pillVar = FinoryxPillVariant.income;
      if (aff.status == 'UNRECOMMENDED') pillVar = FinoryxPillVariant.expense;
      if (aff.status == 'RISKY') pillVar = FinoryxPillVariant.warning;
      if (aff.status == 'MODERATE') pillVar = FinoryxPillVariant.primary;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.aiContainerDark : AppColors.aiContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: insight.statusColor.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FinoryxPill(label: 'DECISION ENGINE', variant: FinoryxPillVariant.ai),
                const Spacer(),
                FinoryxPill(label: aff.status, variant: pillVar),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricCol('Purchase Amount', AppFormatters.currency(aff.purchaseAmount, symbol: currencySymbol), isDark),
                _buildMetricCol('Post-Buy Buffer', AppFormatters.currency(aff.postPurchaseLiquidBuffer, symbol: currencySymbol), isDark),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current Cash Buffer: ${AppFormatters.currency(aff.currentLiquidBuffer, symbol: currencySymbol)}',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ],
        ),
      );
    }

    if (insight.burnRate != null) {
      final burn = insight.burnRate!;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.aiContainerDark : AppColors.aiContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: insight.statusColor.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FinoryxPill(label: 'BURN RATE', variant: FinoryxPillVariant.ai),
                const Spacer(),
                FinoryxPill(label: burn.burnStatus, variant: FinoryxPillVariant.warning),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricCol('Projected Spend', AppFormatters.currency(burn.projectedMonthEndSpend, symbol: currencySymbol), isDark),
                _buildMetricCol('Pace Rate', '${burn.burnRatePercentage.toStringAsFixed(1)}%', isDark),
              ],
            ),
          ],
        ),
      );
    }

    if (insight.savingsGoals != null) {
      final goals = insight.savingsGoals!;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.aiContainerDark : AppColors.aiContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: insight.statusColor.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FinoryxPill(label: 'GOALS PACE', variant: FinoryxPillVariant.ai),
                const Spacer(),
                FinoryxPill(label: '${goals.overallProgressPercentage.toStringAsFixed(1)}% SAVED', variant: FinoryxPillVariant.income),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricCol('Required / Day', AppFormatters.currency(goals.requiredDailySavings, symbol: currencySymbol), isDark),
                _buildMetricCol('Required / Month', AppFormatters.currency(goals.requiredMonthlySavings, symbol: currencySymbol), isDark),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMetricCol(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
