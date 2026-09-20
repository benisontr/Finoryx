import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FinoryxAiInsightCard extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FinoryxAiInsightCard({
    super.key,
    this.title = 'FINORYX INSIGHT',
    required this.message,
    this.actionLabel = 'Ask Assistant →',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2E1065), const Color(0xFF1E1B4B)]
              : [const Color(0xFFFAF5FF), const Color(0xFFEEF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? const Color(0xFF6B21A8) : const Color(0xFFDDD6FE),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.purple : AppColors.aiAccent).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7E22CE) : AppColors.aiAccent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI COPILOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFF3E8FF) : const Color(0xFF1E1B4B),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFC084FC) : AppColors.aiAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
