import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workbench/core/constants/app_colors.dart';
import 'package:workbench/core/constants/app_text_styles.dart';
import 'package:workbench/core/utils/item_utils.dart';
import 'package:workbench/features/items/domain/entities/item_entity.dart';
import 'package:workbench/features/items/domain/entities/item_block.dart';
import 'package:workbench/features/items/presentation/providers/item_providers.dart';
import 'package:workbench/features/items/presentation/widgets/item_type_badge.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  ItemEntity? _item;
  final Map<String, bool> _showPasswords = {};

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.getItem(widget.itemId);
    if (mounted) setState(() => _item = item);
    if (item != null) {
      await ref.read(itemNotifierProvider.notifier).touchItem(item.id);
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Text('اتنسخت ✓', style: AppTextStyles.bodyMedium),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  ItemBlock _legacyToBlock(ItemEntity item) {
    return ItemBlock(
      id: item.id,
      type: item.type,
      content: item.content,
      promptContent: item.promptContent,
      url: item.url,
      website: item.website,
      email: item.email,
      username: item.username,
      encryptedPassword: item.encryptedPassword,
      code: item.code,
      codeLanguage: item.codeLanguage,
      endpoint: item.endpoint,
      method: item.method,
      headersJson: item.headersJson,
      bodyJson: item.bodyJson,
      apiNotes: item.apiNotes,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      );
    }

    final item = _item!;
    final blocks = item.blocks.isEmpty ? [_legacyToBlock(item)] : item.blocks;

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
                  // Nav row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: item.isFavorite ? const Color(0xFFFFD700) : AppColors.textSecondary),
                        onPressed: () async {
                          await ref.read(itemNotifierProvider.notifier).toggleFavorite(item.id, !item.isFavorite);
                          await _loadItem();
                        },
                      ),
                      IconButton(
                        icon: Icon(item.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                            color: item.isPinned ? AppColors.primary : AppColors.textSecondary),
                        onPressed: () async {
                          await ref.read(itemNotifierProvider.notifier).togglePin(item.id, !item.isPinned);
                          await _loadItem();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                        onPressed: () => context.push('/items/${item.id}/edit').then((_) => _loadItem()),
                      ),
                      PopupMenuButton<String>(
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onSelected: (v) async {
                          if (v == 'archive') {
                            await ref.read(itemNotifierProvider.notifier).archiveItem(item.id);
                            if (context.mounted) context.go('/');
                          } else if (v == 'trash') {
                            await ref.read(itemNotifierProvider.notifier).trashItem(item.id);
                            if (context.mounted) context.go('/');
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'archive', child: Text('أرشفة')),
                          PopupMenuItem(
                            value: 'trash',
                            child: Text('حذف', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                        icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ItemTypeBadge(type: item.type),
                  const SizedBox(height: 10),
                  Text(item.title, style: AppTextStyles.displayMedium),
                  const SizedBox(height: 8),
                  Text(ItemUtils.formatDate(item.updatedAt), style: AppTextStyles.caption),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      children: item.tags.map((t) => Chip(
                        label: Text('#$t', style: AppTextStyles.caption),
                        backgroundColor: AppColors.background,
                        side: const BorderSide(color: AppColors.border),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Content Blocks
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: _buildBlockWrapper(blocks[index], item.blocks.isNotEmpty),
                );
              },
              childCount: blocks.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBlockWrapper(ItemBlock block, bool showHeader) {
     final isChild = block.parentId != null;
     final color = ItemUtils.getTypeColor(block.type);
     
     Widget content = _buildBlockContent(block);
     
     if (showHeader && (block.title != null || isChild)) {
        return Container(
          margin: EdgeInsets.only(right: isChild ? 24 : 0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.title != null && block.title!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    border: const Border(bottom: BorderSide(color: AppColors.border)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      Icon(ItemUtils.getTypeIcon(block.type), size: 16, color: color),
                      const SizedBox(width: 8),
                      Text(block.title!, style: AppTextStyles.labelLarge.copyWith(color: color)),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ],
          ),
        );
     } else {
        // Just the content itself
        return content;
     }
  }

  Widget _buildBlockContent(ItemBlock block) {
    switch (block.type) {
      case ItemType.note:
        return _NoteContent(block: block, onCopy: _copy);
      case ItemType.prompt:
        return _PromptContent(block: block, onCopy: _copy);
      case ItemType.link:
        return _LinkContent(block: block, onCopy: _copy, onOpen: _openUrl);
      case ItemType.account:
        return _AccountContent(
          block: block,
          showPassword: _showPasswords[block.id] ?? false,
          onTogglePassword: () => setState(() => _showPasswords[block.id] = !(_showPasswords[block.id] ?? false)),
          onCopy: _copy,
          onOpen: _openUrl,
        );
      case ItemType.snippet:
        return _SnippetContent(block: block, onCopy: _copy);
      case ItemType.api:
        return _ApiContent(block: block, onCopy: _copy);
    }
  }
}

class _NoteContent extends StatelessWidget {
  final ItemBlock block;
  final Function(String, String) onCopy;
  const _NoteContent({required this.block, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.content != null && block.content!.isNotEmpty) ...[
          _ContentCard(
            child: Text(block.content!, style: AppTextStyles.bodyLarge),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.copy_rounded,
            label: 'انسخ الملاحظة',
            onPressed: () => onCopy(block.content!, 'note'),
          ),
        ],
      ],
    );
  }
}

class _PromptContent extends StatelessWidget {
  final ItemBlock block;
  final Function(String, String) onCopy;
  const _PromptContent({required this.block, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.promptContent != null && block.promptContent!.isNotEmpty) ...[
           _ContentCard(
             child: Text(block.promptContent!, style: AppTextStyles.bodyLarge.copyWith(height: 1.7)),
           ),
           const SizedBox(height: 16),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton.icon(
               icon: const Icon(Icons.copy_rounded, size: 16),
               label: const Text('انسخ البرومبت'),
               onPressed: () => onCopy(block.promptContent!, 'prompt'),
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.promptColor,
                 padding: const EdgeInsets.symmetric(vertical: 14),
               ),
             ),
           ),
        ],
      ],
    );
  }
}

class _LinkContent extends StatelessWidget {
  final ItemBlock block;
  final Function(String, String) onCopy;
  final Function(String) onOpen;
  const _LinkContent({required this.block, required this.onCopy, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ContentCard(
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: AppColors.linkColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.url ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.linkColor),
                ),
              ),
            ],
          ),
        ),
        if (block.url != null && block.url!.isNotEmpty) ...[
           const SizedBox(height: 12),
           Row(
             children: [
               Expanded(
                 child: OutlinedButton.icon(
                   icon: const Icon(Icons.copy_rounded, size: 16),
                   label: const Text('انسخ اللينك'),
                   onPressed: () => onCopy(block.url ?? '', 'link'),
                   style: OutlinedButton.styleFrom(
                     foregroundColor: AppColors.text,
                     side: const BorderSide(color: AppColors.border),
                     padding: const EdgeInsets.symmetric(vertical: 12),
                   ),
                 ),
               ),
               const SizedBox(width: 10),
               Expanded(
                 child: ElevatedButton.icon(
                   icon: const Icon(Icons.open_in_new_rounded, size: 16),
                   label: const Text('افتح الموقع'),
                   onPressed: () => onOpen(block.url ?? ''),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.linkColor,
                     padding: const EdgeInsets.symmetric(vertical: 12),
                   ),
                 ),
               ),
             ],
           ),
        ],
      ],
    );
  }
}

class _AccountContent extends StatelessWidget {
  final ItemBlock block;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final Function(String, String) onCopy;
  final Function(String) onOpen;

  const _AccountContent({
    required this.block,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onCopy,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.website != null && block.website!.isNotEmpty)
          _InfoRow(label: 'الموقع', value: block.website!),
        if (block.email != null && block.email!.isNotEmpty)
          _InfoRow(
            label: 'الإيميل',
            value: block.email!,
            onCopy: () => onCopy(block.email!, 'email'),
          ),
        if (block.username != null && block.username!.isNotEmpty)
          _InfoRow(
            label: 'اليوزرنيم',
            value: block.username!,
            onCopy: () => onCopy(block.username!, 'username'),
          ),
        if (block.encryptedPassword != null && block.encryptedPassword!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الباسورد', style: AppTextStyles.labelSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        showPassword
                            ? block.encryptedPassword!
                            : ItemUtils.maskPassword(block.encryptedPassword!),
                        style: showPassword
                            ? AppTextStyles.mono
                            : AppTextStyles.bodyLarge.copyWith(letterSpacing: 2),
                      ),
                    ),
                    IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: onTogglePassword,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 20),
                      onPressed: () => onCopy(block.encryptedPassword!, 'password'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (block.website != null && block.website!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('افتح الموقع'),
              onPressed: () => onOpen(block.website ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accountColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SnippetContent extends StatelessWidget {
  final ItemBlock block;
  final Function(String, String) onCopy;
  const _SnippetContent({required this.block, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.codeLanguage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.snippetColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.snippetColor.withValues(alpha: 0.3)),
            ),
            child: Text(block.codeLanguage!, style: AppTextStyles.labelSmall.copyWith(color: AppColors.snippetColor)),
          ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              block.code ?? '',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFE6EDF3),
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('انسخ الكود'),
            onPressed: () => onCopy(block.code ?? '', 'code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.snippetColor,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ApiContent extends StatelessWidget {
  final ItemBlock block;
  final Function(String, String) onCopy;
  const _ApiContent({required this.block, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ItemUtils.getMethodColor(block.method ?? 'GET').withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      block.method ?? 'GET',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: ItemUtils.getMethodColor(block.method ?? 'GET'),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      block.endpoint ?? '',
                      style: AppTextStyles.mono,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('انسخ الـ URL'),
                onPressed: () => onCopy(block.endpoint ?? '', 'endpoint'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (block.bodyJson != null && block.bodyJson!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.data_object_rounded, size: 16),
                  label: const Text('انسخ JSON'),
                  onPressed: () => onCopy(block.bodyJson ?? '', 'json'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (block.headersJson != null && block.headersJson!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('الـ Headers', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(block.headersJson!, style: AppTextStyles.mono.copyWith(fontSize: 12)),
          ),
        ],
        if (block.bodyJson != null && block.bodyJson!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('الـ Body', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(block.bodyJson!, style: AppTextStyles.mono.copyWith(fontSize: 12)),
          ),
        ],
        if (block.apiNotes != null && block.apiNotes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('ملاحظات', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          _ContentCard(child: Text(block.apiNotes!, style: AppTextStyles.bodyMedium)),
        ],
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Widget child;
  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _InfoRow({required this.label, required this.value, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
          const Spacer(),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
