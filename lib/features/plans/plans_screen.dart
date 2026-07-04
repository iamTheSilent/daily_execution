import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';
import 'idea_folder_screen.dart';
import 'plan_detail_screen.dart';

const _accent = Color(0xFFFF9500);

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  int _tab = 1; // پیش‌فرض: ایده‌ها

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(s.plansScreenTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.add),
          tooltip: _tab == 0 ? s.tabPlans : s.newFolder,
          onPressed: _tab == 0 ? () => _addPlan(s) : () => _addFolder(s),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(s.tabPlans)),
                ButtonSegment(value: 1, label: Text(s.tabIdeas)),
              ],
              selected: {_tab},
              onSelectionChanged: (sel) => setState(() => _tab = sel.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildPlansTab(s),
          _buildIdeasTab(s),
        ],
      ),
    );
  }

  // ─── تب برنامه‌ها ────────────────────────────────────────────────────────────

  Widget _buildPlansTab(AppStrings s) {
    final async = ref.watch(plansProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Text(s.emptyPlans,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.8)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: plans.length,
          itemBuilder: (_, i) => _PlanTile(
            plan: plans[i],
            strings: s,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PlanDetailScreen(plan: plans[i])),
            ),
            onRename: () => _renamePlan(plans[i], s),
            onDelete: () => _deletePlan(plans[i], s),
          ),
        );
      },
    );
  }

  Future<void> _addPlan(AppStrings s) async {
    final name = await _inputSheet(context, hint: s.newPlanHint);
    if (name == null || name.trim().isEmpty) return;
    await ref.read(planRepositoryProvider).createPlan(name.trim());
  }

  Future<void> _renamePlan(Plan plan, AppStrings s) async {
    final name =
        await _inputSheet(context, hint: s.newPlanHint, initial: plan.name);
    if (name == null || name.trim().isEmpty) return;
    await ref.read(planRepositoryProvider).renamePlan(plan.id, name.trim());
  }

  Future<void> _deletePlan(Plan plan, AppStrings s) async {
    if (!await _confirmDelete(s)) return;
    await ref.read(planRepositoryProvider).deletePlan(plan.id);
  }

  // ─── تب ایده‌ها (لیستِ پوشه‌ها) ───────────────────────────────────────────────

  Widget _buildIdeasTab(AppStrings s) {
    final foldersAsync = ref.watch(ideaFoldersProvider);
    final ideasAsync = ref.watch(ideasProvider);

    return foldersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (folders) {
        final ideas = ideasAsync.valueOrNull ?? const <Task>[];
        final uncategorized =
            ideas.where((t) => t.ideaFolderId == null).length;

        if (folders.isEmpty && uncategorized == 0) {
          return Center(
            child: Text(s.emptyFolders,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.8)),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            for (final f in folders)
              _FolderTile(
                title: f.name,
                icon: f.icon ?? '📁',
                count: ideas.where((t) => t.ideaFolderId == f.id).length,
                strings: s,
                onOpen: () => _openFolder(f),
                onEdit: () => _editFolder(f, s),
                onDelete: () => _deleteFolder(f, s),
              ),
            if (uncategorized > 0)
              _FolderTile(
                title: s.uncategorized,
                icon: '🗂️',
                count: uncategorized,
                strings: s,
                onOpen: () => _openFolder(null),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton.icon(
                onPressed: () => _addFolder(s),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(s.newFolder),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openFolder(IdeaFolder? folder) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IdeaFolderScreen(folder: folder)),
    );
  }

  Future<void> _addFolder(AppStrings s) async {
    final res = await _folderSheet(context, s);
    if (res == null) return;
    await ref.read(ideaRepositoryProvider).createFolder(res.name, res.icon);
  }

  Future<void> _editFolder(IdeaFolder f, AppStrings s) async {
    final res = await _folderSheet(context, s,
        initialName: f.name, initialIcon: f.icon);
    if (res == null) return;
    await ref
        .read(ideaRepositoryProvider)
        .renameFolder(f.id, res.name, res.icon);
  }

  Future<void> _deleteFolder(IdeaFolder f, AppStrings s) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteFolderQ),
        content: Text(s.deleteFolderMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancelLabel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'keep'),
              child: Text(s.keepIdeasLabel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'all'),
              child: Text(s.deleteAllLabel,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    final repo = ref.read(ideaRepositoryProvider);
    if (choice == 'all') {
      await repo.deleteFolderAndIdeas(f.id);
    } else if (choice == 'keep') {
      await repo.deleteFolderKeepIdeas(f.id);
    }
  }

  // ─── ابزارهای کمکی ───────────────────────────────────────────────────────────

  Future<String?> _inputSheet(BuildContext ctx,
      {required String hint, String initial = ''}) {
    final ctrl = TextEditingController(text: initial);
    return showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(hintText: hint),
              onSubmitted: (v) => Navigator.pop(sheetCtx, v),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(sheetCtx, ctrl.text),
          ),
        ]),
      ),
    );
  }

  Future<({String name, String? icon})?> _folderSheet(
      BuildContext ctx, AppStrings s,
      {String initialName = '', String? initialIcon}) {
    final nameCtrl = TextEditingController(text: initialName);
    final iconCtrl = TextEditingController(text: initialIcon ?? '');

    void submit(BuildContext sheetCtx) {
      final n = nameCtrl.text.trim();
      if (n.isEmpty) {
        Navigator.pop(sheetCtx);
        return;
      }
      final ic = iconCtrl.text.trim();
      Navigator.pop(sheetCtx, (name: n, icon: ic.isEmpty ? null : ic));
    }

    return showModalBottomSheet<({String name, String? icon})>(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Row(children: [
          SizedBox(
            width: 56,
            child: TextField(
              controller: iconCtrl,
              textAlign: TextAlign.center,
              maxLength: 2,
              buildCounter: (_,
                      {required int currentLength,
                      required bool isFocused,
                      int? maxLength}) =>
                  null,
              decoration: const InputDecoration(hintText: '📁'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(hintText: s.folderNameHint),
              onSubmitted: (_) => submit(sheetCtx),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => submit(sheetCtx),
          ),
        ]),
      ),
    );
  }

  Future<bool> _confirmDelete(AppStrings s) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.deleteConfirmQ),
          content: Text(s.deleteConfirmMsg),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancelLabel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.deleteLabel,
                    style: const TextStyle(color: Colors.red))),
          ],
        ),
      ) ??
      false;
}

// ─── کارتِ برنامه (درشت + پراگرس‌بار) ───────────────────────────────────────────

class _PlanTile extends ConsumerWidget {
  const _PlanTile({
    required this.plan,
    required this.strings,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });
  final Plan plan;
  final AppStrings strings;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(planTasksProvider(plan.id)).valueOrNull ??
        const <Task>[];
    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final total = tasks.length;
    final remaining = total - done;
    final progress = total == 0 ? 0.0 : done / total;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.folder_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(plan.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'rename') onRename();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'rename', child: Text(strings.renameLabel)),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(strings.deleteLabel,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Text('$remaining ${strings.remainingLabel}',
                    style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(width: 10),
                Text('$done/$total ${strings.doneLabel}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(_accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── کارتِ پوشه ─────────────────────────────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.title,
    required this.icon,
    required this.count,
    required this.strings,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
  });
  final String title;
  final String icon;
  final int count;
  final AppStrings strings;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasMenu = onEdit != null || onDelete != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onOpen,
        leading: Text(icon, style: const TextStyle(fontSize: 24)),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(strings.ideaCount(count)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMenu)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit?.call();
                  if (v == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    PopupMenuItem(
                        value: 'edit', child: Text(strings.editFolder)),
                  if (onDelete != null)
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(strings.deleteLabel,
                            style: const TextStyle(color: Colors.red))),
                ],
              ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}