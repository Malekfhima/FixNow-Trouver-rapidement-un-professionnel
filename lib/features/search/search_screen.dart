import 'package:flutter/material.dart';
import 'package:fixnow/core/theme/app_theme.dart';

/// Search screen with filters and professional listings.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _categories = [
    'Tous',
    'Plomberie',
    'Ménage',
    'Électricité',
    'Menuiserie',
    'Peinture',
    'Serrurerie',
    'Mécanique',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rechercher'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un service ou un pro...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              autofocus: true,
            ),
          ),

          // Category tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: AppTextStyles.buttonMedium,
            unselectedLabelStyle: AppTextStyles.buttonMedium,
            tabs: _categories.map((c) => Tab(text: c)).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Results placeholder
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Recherchez un service\nou un professionnel',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
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
}
