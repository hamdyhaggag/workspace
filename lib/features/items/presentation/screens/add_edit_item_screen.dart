import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workbench/core/constants/app_colors.dart';
import 'package:workbench/core/constants/app_text_styles.dart';
import 'package:workbench/core/utils/item_utils.dart';
import 'package:workbench/features/items/domain/entities/item_entity.dart';
import 'package:workbench/features/items/presentation/providers/item_providers.dart';
import 'package:workbench/features/projects/presentation/providers/project_providers.dart';
import '../states/block_state.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final String? itemId;
  final ItemType? initialType;
  final String? initialProjectId;

  const AddEditItemScreen({
    super.key,
    this.itemId,
    this.initialType,
    this.initialProjectId,
  });

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _projectId;
  bool _isLoading = false;
  ItemEntity? _existingItem;

  final _titleCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  List<BlockState> _blocks = [];

  @override
  void initState() {
    super.initState();
    _projectId = widget.initialProjectId;
    if (widget.itemId != null) {
      _loadExisting();
    } else {
      // Start with one block
      _blocks.add(BlockState(type: widget.initialType ?? ItemType.note));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _tagsCtrl.dispose();
    for (var b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.getItem(widget.itemId!);
    if (item != null && mounted) {
      setState(() {
        _existingItem = item;
        _projectId = item.projectId;
        _titleCtrl.text = item.title;
        _tagsCtrl.text = item.tags.join(', ');
        
        // Load blocks
        _blocks.clear();
        
        // If there's root-level content and no blocks, convert to a block
        if (item.blocks.isEmpty) {
          final rootBlock = BlockState.fromRootEntity(item);
          if (rootBlock.hasContent) {
            _blocks.add(rootBlock);
          } else {
             // Fallback empty block
            _blocks.add(BlockState(type: item.type));
          }
        } else {
          // Both blocks and root content might exist (transitionary), but we favor blocks array
          _blocks.addAll(item.blocks.map((b) => BlockState.fromEntity(b)));
        }
        
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _parseTags(String raw) {
    return raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  void _addBlock(ItemType type, {String? parentId}) {
    setState(() {
      _blocks.add(BlockState(type: type, parentId: parentId));
    });
  }

  void _removeBlock(BlockState block) {
    setState(() {
      _blocks.removeWhere((b) => b.id == block.id || b.parentId == block.id);
      block.dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختار مشروع الأول')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(itemNotifierProvider.notifier);
      final tags = _parseTags(_tagsCtrl.text);

      final itemBlocks = _blocks.map((b) => b.toItemBlock()).toList();
      // Derive primary type from the first block or default to Note
      final primaryType = itemBlocks.isNotEmpty ? itemBlocks.first.type : (widget.initialType ?? ItemType.note);

      // We migrate top level content into the first block, or just clear them to keep it clean.
      // We will save to blocks array, and clear out the old properties if present.
      
      if (_existingItem != null) {
        final updated = _existingItem!.copyWith(
          title: _titleCtrl.text.trim(),
          tags: tags,
          type: primaryType,
          blocks: itemBlocks,
          content: null, promptContent: null, url: null, website: null, email: null, username: null,
          encryptedPassword: null, code: null, codeLanguage: null, endpoint: null, method: null,
          headersJson: null, bodyJson: null, apiNotes: null,
        );
        await notifier.updateItem(updated);
        if (mounted) context.go('/items/${_existingItem!.id}');
      } else {
        final id = await notifier.createItem(
          projectId: _projectId!,
          title: _titleCtrl.text.trim(),
          type: primaryType,
          tags: tags,
          // Root fields are left null as content is in blocks now using a modified create request...
          // Wait, createItem method in notifier signature requires modifying if we pass blocks?!
          // Wait! Let's check if createItem accepts blocks. If not, we might need to use generic create logic or update createItem signature.
        );
        // Oh right, we need to update the notifier and repository to accept blocks in createItem, or we can just create it with empty root and then update immediately!
        // This is safe since we already added blocks to itemEntity copyWith. But let's check createItem signature later. Let's assume we can update it or just create then update.
        if (mounted) {
           final createdItem = await ref.read(itemRepositoryProvider).getItem(id);
           if (createdItem != null) {
             final updated = createdItem.copyWith(blocks: itemBlocks);
             await notifier.updateItem(updated);
           }
           if (mounted) context.go('/items/$id');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final isEdit = _existingItem != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading && _existingItem == null && widget.itemId != null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.go(_existingItem != null ? '/items/${_existingItem!.id}' : '/'),
                                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(isEdit ? 'تعديل' : 'إضافة عنصر', style: AppTextStyles.displayLarge),
                          const SizedBox(height: 24),

                          // Project selector
                          Text('المشروع', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 8),
                          projectsAsync.when(
                            loading: () => const LinearProgressIndicator(color: AppColors.primary),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (projects) => DropdownButtonFormField<String>(
                              initialValue: _projectId,
                              dropdownColor: AppColors.card,
                              style: AppTextStyles.bodyMedium,
                              decoration: const InputDecoration(hintText: 'اختار المشروع'),
                              items: projects.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.emoji} ${p.name}'),
                              )).toList(),
                              onChanged: (v) => setState(() => _projectId = v),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(labelText: 'العنوان *'),
                            style: AppTextStyles.bodyLarge,
                            validator: (v) => v?.isEmpty == true ? 'لازم تكتب عنوان' : null,
                          ),
                          const SizedBox(height: 16),

                          // Tags
                          TextFormField(
                            controller: _tagsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'التاجات',
                              hintText: 'Flutter, Firebase, AI',
                            ),
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Text('محتويات العنصر', style: AppTextStyles.labelLarge),
                              const Spacer(),
                              _buildAddBlockDropdown(null, label: 'إضافة بلوك'),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Blocks list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                         if (index >= _blocks.length) return null;
                         final block = _blocks[index];
                         return Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                           child: _buildBlockWidget(block, index),
                         );
                      },
                      childCount: _blocks.length,
                    ),
                  ),

                  // Save Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.background,
                                  ),
                                )
                              : Text(
                                  isEdit ? 'حفظ التعديلات' : 'حفظ العنصر',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildAddBlockDropdown(String? parentId, {required String label}) {
     return PopupMenuButton<ItemType>(
        tooltip: label,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
        color: AppColors.card,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        onSelected: (type) => _addBlock(type, parentId: parentId),
        itemBuilder: (context) {
          return ItemType.values.map((t) => PopupMenuItem(
            value: t,
            child: Row(
               children: [
                 Icon(ItemUtils.getTypeIcon(t), color: ItemUtils.getTypeColor(t), size: 18),
                 const SizedBox(width: 8),
                 Text(ItemUtils.getTypeLabel(t)),
               ],
            ),
          )).toList();
        },
     );
  }

  Widget _buildBlockWidget(BlockState block, int index) {
     final color = ItemUtils.getTypeColor(block.type);
     final isChild = block.parentId != null;
     
     return Container(
       margin: EdgeInsets.only(right: isChild ? 24 : 0),
       decoration: BoxDecoration(
         color: AppColors.card,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: isChild ? AppColors.border : color.withValues(alpha: 0.5), width: isChild ? 1 : 1.5),
       ),
       child: Column(
         children: [
           // Header
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
               color: color.withValues(alpha: 0.05),
               border: const Border(bottom: BorderSide(color: AppColors.border)),
               borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
             ),
             child: Row(
               children: [
                 Icon(ItemUtils.getTypeIcon(block.type), color: color, size: 18),
                 const SizedBox(width: 10),
                 Expanded(
                   child: TextFormField(
                      controller: block.titleCtrl,
                      decoration: InputDecoration(
                        hintText: '${ItemUtils.getTypeLabel(block.type)} (اختياري)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: AppTextStyles.labelLarge.copyWith(color: color),
                   ),
                 ),
                 if (!isChild)
                    _buildAddBlockDropdown(block.id, label: 'تفرع'),
                 const SizedBox(width: 8),
                 IconButton(
                    icon: Icon(block.isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    onPressed: () => setState(() => block.isExpanded = !block.isExpanded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                 ),
                 const SizedBox(width: 4),
                 IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                    onPressed: () => _removeBlock(block),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                 ),
               ],
             ),
           ),
           // Body
           if (block.isExpanded)
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildBlockFields(block),
              )
         ],
       ),
     );
  }

  Widget _buildBlockFields(BlockState block) {
    switch (block.type) {
      case ItemType.note:
        return TextFormField(
          controller: block.contentCtrl,
          maxLines: null, minLines: 4,
          decoration: const InputDecoration(labelText: 'المحتوى', alignLabelWithHint: true),
          style: AppTextStyles.bodyLarge,
        );
      case ItemType.prompt:
        return TextFormField(
          controller: block.promptCtrl,
          maxLines: null, minLines: 5,
          decoration: const InputDecoration(labelText: 'البرومبت', alignLabelWithHint: true),
          style: AppTextStyles.bodyLarge.copyWith(height: 1.7),
        );
      case ItemType.link:
        return TextFormField(
          controller: block.urlCtrl,
          decoration: const InputDecoration(labelText: 'الرابط'),
          keyboardType: TextInputType.url,
          style: AppTextStyles.bodyMedium,
        );
      case ItemType.account:
        return Column(
          children: [
            TextFormField(controller: block.websiteCtrl, decoration: const InputDecoration(labelText: 'الموقع')),
            const SizedBox(height: 12),
            TextFormField(controller: block.emailCtrl, decoration: const InputDecoration(labelText: 'الإيميل'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextFormField(controller: block.usernameCtrl, decoration: const InputDecoration(labelText: 'اليوزرنيم')),
            const SizedBox(height: 12),
            TextFormField(
              controller: block.passwordCtrl,
              obscureText: !block.showPassword,
              decoration: InputDecoration(
                labelText: 'الباسورد',
                suffixIcon: IconButton(
                  icon: Icon(block.showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary),
                  onPressed: () => setState(() => block.showPassword = !block.showPassword),
                ),
              ),
            ),
          ],
        );
      case ItemType.snippet:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: block.codeLanguage,
              dropdownColor: AppColors.card,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(labelText: 'اللغة'),
              items: ['Dart', 'Flutter', 'JavaScript', 'TypeScript', 'Python', 'SQL', 'HTML', 'CSS', 'JSON', 'Kotlin', 'Swift', 'Bash']
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => block.codeLanguage = v ?? 'Dart'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: block.codeCtrl,
              maxLines: null, minLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.text),
              decoration: const InputDecoration(labelText: 'الكود', alignLabelWithHint: true),
            ),
          ],
        );
      case ItemType.api:
        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<String>(
                    initialValue: block.method,
                    dropdownColor: AppColors.card,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(labelText: 'الميثود'),
                    items: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => block.method = v ?? 'GET'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: block.endpointCtrl,
                    decoration: const InputDecoration(labelText: 'الرابط (Endpoint)'),
                    style: AppTextStyles.mono,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: block.headersCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'الـ Headers (JSON)', alignLabelWithHint: true),
              style: AppTextStyles.mono.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: block.bodyCtrl,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'الـ Body (JSON)', alignLabelWithHint: true),
              style: AppTextStyles.mono.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: block.apiNotesCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'ملاحظات', alignLabelWithHint: true),
              style: AppTextStyles.bodyMedium,
            ),
          ],
        );
    }
  }
}
