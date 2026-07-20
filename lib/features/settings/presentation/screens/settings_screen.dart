import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workbench/core/constants/app_colors.dart';
import 'package:workbench/core/constants/app_text_styles.dart';
import 'package:workbench/features/auth/presentation/providers/auth_providers.dart';
import 'package:workbench/features/items/presentation/providers/item_providers.dart';
import 'package:workbench/features/projects/presentation/providers/project_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final projectsAsync = ref.watch(projectsStreamProvider);
    final recentAsync = ref.watch(recentItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإعدادات', style: AppTextStyles.displayLarge),
                  const SizedBox(height: 28),

                  // User Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: user?.photoURL == null
                              ? Text(
                                  (user?.displayName ?? 'U')[0].toUpperCase(),
                                  style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'مستخدم',
                                style: AppTextStyles.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'متصل',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Stats
                  Text('إحصائيات', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.folder_rounded,
                          label: 'مشاريع',
                          value: projectsAsync.whenOrNull(data: (p) => p.length.toString()) ?? '—',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.layers_rounded,
                          label: 'عناصر',
                          value: recentAsync.whenOrNull(data: (i) => i.length.toString()) ?? '—',
                          color: AppColors.linkColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // General Section
                  Text('عام', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.archive_outlined,
                        label: 'الأرشيف',
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        onTap: () => context.go('/archive'),
                      ),
                      _SettingsTile(
                        icon: Icons.delete_outline_rounded,
                        label: 'المحذوفات',
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        onTap: () => context.go('/trash'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Keyboard shortcuts
                  Text('اختصارات الكيبورد', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    children: [
                      _ShortcutTile(label: 'البحث السريع', shortcut: 'Ctrl + K'),
                      _ShortcutTile(label: 'إغلاق', shortcut: 'Esc'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // About
                  Text('عن التطبيق', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.workspaces_rounded,
                        label: 'WorkSpace',
                        trailing: Text('v1.0.0', style: AppTextStyles.caption),
                      ),
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        label: 'بياناتك محمية على Firebase',
                        iconColor: AppColors.success,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Sign out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, ref),
                      icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                      label: Text('تسجيل خروج', style: AppTextStyles.labelLarge.copyWith(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('تسجيل خروج؟'),
        content: Text(
          'هتخرج من حسابك، بياناتك محفوظة على السيرفر',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.headlineLarge.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, color: AppColors.border, indent: 52),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, this.trailing, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final String label;
  final String shortcut;
  const _ShortcutTile({required this.label, required this.shortcut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.keyboard_rounded, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(shortcut, style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}
