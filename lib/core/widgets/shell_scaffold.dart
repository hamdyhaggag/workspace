import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'command_palette.dart';
import 'quick_add_fab.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  bool _showCommandPalette = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyK &&
        HardwareKeyboard.instance.isControlPressed) {
      setState(() => _showCommandPalette = !_showCommandPalette);
      return true;
    }
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (_showCommandPalette) {
        setState(() => _showCommandPalette = false);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 640 && width < 1024;
    final location = GoRouterState.of(context).matchedLocation;

    // Hide FAB on navigation pages and forms
    final hideFabRoutes = ['/', '/projects', '/search', '/settings', '/add', '/archive', '/trash'];
    final showFab = !hideFabRoutes.contains(location) && !location.endsWith('/edit');

    // Extract project ID to link added items
    String? defaultProjectId;
    if (location.startsWith('/projects/') && location != '/projects') {
      final segments = location.split('/');
      if (segments.length > 2) {
        defaultProjectId = segments[2];
      }
    }

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (e) {},
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            body: isDesktop
                ? _DesktopLayout(child: widget.child)
                : isTablet
                    ? _TabletLayout(child: widget.child)
                    : _MobileLayout(child: widget.child),
            floatingActionButton: showFab ? QuickAddFab(defaultProjectId: defaultProjectId) : null,
          ),
          if (_showCommandPalette)
            CommandPalette(
              onClose: () => setState(() => _showCommandPalette = false),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}

final _navItems = [
  const _NavItem(label: 'الرئيسية', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, path: '/'),
  const _NavItem(label: 'المشاريع', icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded, path: '/projects'),
  const _NavItem(label: 'دور', icon: Icons.search_outlined, activeIcon: Icons.search_rounded, path: '/search'),
  const _NavItem(label: 'الإعدادات', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, path: '/settings'),
];

class _DesktopLayout extends ConsumerWidget {
  final Widget child;
  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Row(
      children: [
        Container(
          width: 220,
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              ..._navItems.map((item) {
                final isActive = location == item.path ||
                    (item.path != '/' && location.startsWith(item.path));
                return _SideNavItem(item: item, isActive: isActive);
              }),
              const Spacer(),
              const Divider(height: 1, color: AppColors.border),
              _SideNavItem(
                item: const _NavItem(
                  label: 'الأرشيف',
                  icon: Icons.archive_outlined,
                  activeIcon: Icons.archive_rounded,
                  path: '/archive',
                ),
                isActive: location == '/archive',
              ),
              _SideNavItem(
                item: const _NavItem(
                  label: 'المحذوفات',
                  icon: Icons.delete_outline_rounded,
                  activeIcon: Icons.delete_rounded,
                  path: '/trash',
                ),
                isActive: location == '/trash',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _SideNavItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go(item.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabletLayout extends ConsumerWidget {
  final Widget child;
  const _TabletLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Row(
      children: [
        Container(
          width: 64,
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 36,
                  height: 36,
                  alignment: Alignment.topCenter,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              ..._navItems.map((item) {
                final isActive = location == item.path ||
                    (item.path != '/' && location.startsWith(item.path));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Tooltip(
                    message: item.label,
                    child: IconButton(
                      icon: Icon(isActive ? item.activeIcon : item.icon),
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      onPressed: () => context.go(item.path),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  final Widget child;
  const _MobileLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: _navItems.map((item) {
                final isActive = location == item.path ||
                    (item.path != '/' && location.startsWith(item.path));
                return Expanded(
                  child: InkWell(
                    onTap: () => context.go(item.path),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive ? AppColors.primary : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTextStyles.caption.copyWith(
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
