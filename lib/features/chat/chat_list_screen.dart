import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Chat list screen showing all conversations.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Messages')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucun message',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Vos conversations apparaîtront ici',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
