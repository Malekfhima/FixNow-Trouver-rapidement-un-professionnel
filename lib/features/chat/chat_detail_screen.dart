import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Chat detail screen for a single conversation.
class ChatDetailScreen extends StatelessWidget {
  final String chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryContainer,
              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marc Lefebvre', style: AppTextStyles.h4),
                Text('En ligne', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: Center(
              child: Text(
                'Commencez la conversation...',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined,
                        color: AppColors.textHint),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.fullAll,
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: AppColors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
