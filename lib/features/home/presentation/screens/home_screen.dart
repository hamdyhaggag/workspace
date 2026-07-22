import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workbench/core/constants/app_colors.dart';
import 'package:workbench/core/constants/app_text_styles.dart';
import 'package:workbench/features/projects/presentation/providers/project_providers.dart';
import 'package:workbench/features/items/presentation/providers/item_providers.dart';
import 'package:workbench/features/items/presentation/widgets/item_card.dart';
import 'package:workbench/features/projects/domain/entities/project_entity.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 16) return 'مساء الخير';
    return 'مساء النور';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final projectsAsync = ref.watch(projectsStreamProvider);
    final pinnedAsync = ref.watch(pinnedItemsProvider);
    final recentAsync = ref.watch(recentItemsProvider);

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 640;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile) ...[
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: AppTextStyles.displayLarge),
                          if (user?.displayName != null)
                            Text(
                              user!.displayName!.split(' ').first,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          ref.invalidate(projectsStreamProvider);
                          ref.invalidate(pinnedItemsProvider);
                          ref.invalidate(recentItemsProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث البيانات'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: 'تحديث',
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        backgroundColor: AppColors.card,
                        child: user?.photoURL == null
                            ? const Icon(
                                Icons.person_rounded,
                                color: AppColors.textSecondary,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quick search bar
                  GestureDetector(
                    onTap: () => context.go('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'دور على أي حاجة...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text('Ctrl K', style: AppTextStyles.caption),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: projectsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (projects) => recentAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => _StatsRow(projects: projects, items: items),
              ),
            ),
          ),

          // Pinned Items
          pinnedAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (pinned) => pinned.isEmpty
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : SliverToBoxAdapter(
                    child: _Section(
                      title: 'المثبتات',
                      icon: Icons.push_pin_rounded,
                      child: SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: pinned.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: 260,
                            child: ItemCard(item: pinned[i], compact: true),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // Recent Items
          recentAsync.when(
            loading: () => const SliverToBoxAdapter(child: _LoadingState()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (items) => items.isEmpty
                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                : SliverToBoxAdapter(
                    child: _Section(
                      title: 'آخر اللي اشتغلت عليه',
                      icon: Icons.history_rounded,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: items.take(6).length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => ItemCard(item: items[i]),
                      ),
                    ),
                  ),
          ),

          // Recent Projects
          projectsAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (projects) => projects.isEmpty
                ? const SliverToBoxAdapter(child: _EmptyHomeState())
                : SliverToBoxAdapter(
                    child: _Section(
                      title: 'المشاريع',
                      icon: Icons.folder_rounded,
                      trailing: TextButton(
                        onPressed: () => context.go('/projects'),
                        child: Text(
                          'كل المشاريع',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.4,
                            ),
                        itemCount: projects.take(6).length,
                        itemBuilder: (_, i) =>
                            _ProjectMiniCard(project: projects[i]),
                      ),
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List projects;
  final List items;
  const _StatsRow({required this.projects, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'مشاريع',
            value: projects.length.toString(),
            icon: Icons.folder_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'عناصر',
            value: items.length.toString(),
            icon: Icons.layers_rounded,
            color: AppColors.linkColor,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'مثبتات',
            value: items
                .where((i) => (i as dynamic).isPinned == true)
                .length
                .toString(),
            icon: Icons.push_pin_rounded,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headlineLarge.copyWith(color: color),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.headlineMedium),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _ProjectMiniCard extends StatelessWidget {
  final ProjectEntity project;
  const _ProjectMiniCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/projects/${project.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.emoji, style: const TextStyle(fontSize: 24)),
            const Spacer(),
            Text(
              project.name,
              style: AppTextStyles.labelLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('${project.itemCount} عنصر', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Text('🚀', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('ابدأ مشروعك الأول', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'اضغط + لإضافة مشروع أو عنصر',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
