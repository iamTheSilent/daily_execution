import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date/app_date.dart';
import '../../core/date/wheel_picker.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';
import 'idea_detail_screen.dart';

class IdeaFolderScreen extends ConsumerWidget {
  const IdeaFolderScreen({super.key, this.folder});
  final IdeaFolder? folder;

  String? get _folderId => folder?.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final ideasAsync = ref.watch(ideasProvider);
    final title = folder?.name ?? s.uncategorized;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        onPressed: () => _addIdea(context, ref, s),
        child: const Icon(Icons.add),
      ),
      body: ideasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final ideas =
              all.where((t) => t.ideaFolderId == _folderId).toList();
          if (ideas.isEmpty) {
            return Center(
              child: Text(s.emptyFolderIdeas,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.8)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: ideas.length,
            itemBuilder: (_, i) => _IdeaRow(
              idea: ideas[i],
              strings: s,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => IdeaDetailScreen(idea: ideas[i])),
              ),
              onCycle: () =>
                  ref.read(ideaRepositoryProvider).cycleStatus(ideas[i]),
              onActions: () => _showActions(context, ref, s, ideas[i]),
            ),
          );
        },
      ),
    );
  }

  // ── افزودنِ ایده داخلِ همین پوشه ──
  Future<void> _addIdea(
      BuildContext context, WidgetRef ref, AppStrings s) async {
    final title = await _inputSheet(context, hint: s.newIdeaHint);
    if (title == null || title.trim().isEmpty) return;
    await ref
        .read(ideaRepositoryProvider)
        .addIdea(title.trim(), folderId: _folderId);
  }

  // ── شیتِ اکشن‌ها (۵ گزینه) ──
  void _showActions(
      BuildContext context, WidgetRef ref, AppStrings s, Task idea) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bolt, color: AppColors.accent),
              title: Text(s.convertToTask,
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _convertToTask(context, ref, s, idea);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(s.scheduleToDay),
              onTap: () {
                Navigator.pop(sheetCtx);
                _scheduleToDay(context, ref, s, idea);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(s.addToPlan),
              onTap: () {
                Navigator.pop(sheetCtx);
                _addToPlan(context, ref, s, idea);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: Text(s.moveToFolder),
              onTap: () {
                Navigator.pop(sheetCtx);
                _moveToFolder(context, ref, s, idea);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(s.deleteLabel,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _delete(context, ref, s, idea);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToTask(
      BuildContext context, WidgetRef ref, AppStrings s, Task idea) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(ideaRepositoryProvider).sendToDay(idea, DateTime.now());
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
        content: Text(s.sentToTodayMsg),
        duration: const Duration(milliseconds: 1500)));
  }

  Future<void> _scheduleToDay(
      BuildContext context, WidgetRef ref, AppStrings s, Task idea) async {
    final mode = ref.read(calendarModeProvider);
    final isFa = ref.read(localeProvider).languageCode == 'fa';
    final picked = await showWheelDateTime(context,
        initial: idea.dueDate, mode: mode, isFa: isFa);
    if (picked == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(ideaRepositoryProvider).sendToDay(idea, picked);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
        content: Text(s.scheduledMsg),
        duration: const Duration(milliseconds: 1500)));
  }

  Future<void> _addToPlan(
      BuildContext context, WidgetRef ref, AppStrings s, Task idea) async {
    final plans = ref.read(plansProvider).valueOrNull ?? const <Plan>[];
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(s.noPlansToPick),
            duration: const Duration(milliseconds: 1500)));
      return;
    }
    final planId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.pickPlan,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final p in plans)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(p.name),
                onTap: () => Navigator.pop(sheetCtx, p.id),
              ),
          ],
        ),
      ),
    );
    if (planId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(ideaRepositoryProvider).addToPlan(idea, planId);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
        content: Text(s.addedToPlanMsg),
        duration: const Duration(milliseconds: 1500)));
  }

  Future<void> _moveToFolder(
      BuildContext context, WidgetRef ref, AppStrings s, Task idea) async {
    final folders =
        ref.read(ideaFoldersProvider).valueOrNull ?? const <IdeaFolder>[];
    final selected = await showModalBottomSheet<_MoveTarget>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.pickFolder,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (idea.ideaFolderId != null)
              ListTile(
                leading: const Text('🗂️', style: TextStyle(fontSize: 22)),
                title: Text(s.uncategorized),
                onTap: () =>
                    Navigator.pop(sheetCtx, const _MoveTarget(null)),
              ),
            for (final f in folders)
              if (f.id != idea.ideaFolderId)
                ListTile(
                  leading:
                      Text(f.icon ?? '📁', style: const TextStyle(fontSize: 22)),
                  title: Text(f.name),
                  onTap: () => Navigator.pop(sheetCtx, _MoveTarget(f.id)),
                ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(ideaRepositoryProvider)
        .moveToFolder(idea.id, selected.id);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
        content: Text(s.movedMsg),
        duration: const Duration(milliseconds: 1500)));
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, AppStrings s, Task idea) async {
    final ok = await showDialog<bool>(
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
    if (!ok) return;
    await ref.read(ideaRepositoryProvider).deleteIdea(idea.id);
  }

  Future<String?> _inputSheet(BuildContext ctx, {required String hint}) {
    final ctrl = TextEditingController();
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
}

class _MoveTarget {
  const _MoveTarget(this.id);
  final String? id;
}

// ─── ردیفِ ایده ──────────────────────────────────────────────────────────────────

class _IdeaRow extends StatelessWidget {
  const _IdeaRow({
    required this.idea,
    required this.strings,
    required this.onOpen,
    required this.onCycle,
    required this.onActions,
  });
  final Task idea;
  final AppStrings strings;
  final VoidCallback onOpen;
  final VoidCallback onCycle;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final isDone = idea.status == TaskStatus.done;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onOpen,
        leading: GestureDetector(
          onTap: onCycle,
          child: _StatusCircle(status: idea.status),
        ),
        title: Text(
          idea.title,
          style: TextStyle(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? AppColors.textSecondary : null,
          ),
        ),
        subtitle: (idea.note == null || idea.note!.isEmpty)
            ? null
            : Text(idea.note!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: onActions,
        ),
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TaskStatus.done:
        return const Icon(Icons.check_circle, color: AppColors.green);
      case TaskStatus.doing:
        return const Icon(Icons.radio_button_checked, color: AppColors.accent);
      case TaskStatus.todo:
        return const Icon(Icons.radio_button_unchecked,
            color: AppColors.textSecondary);
    }
  }
}