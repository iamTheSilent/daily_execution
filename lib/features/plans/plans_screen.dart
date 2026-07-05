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
import 'plan_detail_screen.dart';

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
          tooltip: _tab == 0 ? s.tabPlans : s.tabIdeas,
          onPressed: _tab == 0 ? () => _addPlan(s) : () => _addIdea(s),
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
    final async = ref.watch(plansWithProgressProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(s.emptyPlans,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.8)),
          );
        }

        final active = items.where((e) => !e.plan.archived).toList()
          ..sort(_comparePlans);
        final archived = items.where((e) => e.plan.archived).toList()
          ..sort((a, b) => a.plan.orderKey.compareTo(b.plan.orderKey));

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            if (active.isEmpty && archived.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.emptyPlans,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, height: 1.8)),
              ),
            ...active.map((item) => _planTileFor(item, s)),
            if (archived.isNotEmpty) ...[
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                  childrenPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.archive_outlined,
                      color: AppColors.textSecondary),
                  title: Text(
                    '${s.archivedSection} (${s.number(archived.length)})',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  children:
                      archived.map((item) => _planTileFor(item, s)).toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _planTileFor(PlanWithProgress item, AppStrings s) => _PlanTile(
        item: item,
        strings: s,
        onOpen: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: item.plan)),
        ),
        onRename: () => _editPlan(item.plan, s),
        onDelete: () => _deletePlan(item.plan, s),
        onTogglePin: () => ref
            .read(planRepositoryProvider)
            .setPinned(item.plan.id, !item.plan.pinned),
        onToggleArchive: () => _toggleArchive(item, s),
      );

  Future<void> _addPlan(AppStrings s) async {
    final res = await _planSheet(context, s);
    if (res == null) return;
    await ref.read(planRepositoryProvider).createPlan(res.name, icon: res.icon);
  }

  Future<void> _editPlan(Plan plan, AppStrings s) async {
    final res = await _planSheet(context, s,
        initialName: plan.name, initialIcon: plan.icon);
    if (res == null) return;
    await ref
        .read(planRepositoryProvider)
        .updatePlan(plan.id, name: res.name, icon: res.icon);
  }

  Future<void> _deletePlan(Plan plan, AppStrings s) async {
    if (!await _confirmDelete(s)) return;
    await ref.read(planRepositoryProvider).deletePlan(plan.id);
  }

  Future<void> _toggleArchive(PlanWithProgress item, AppStrings s) async {
    final messenger = ScaffoldMessenger.of(context);
    final nowArchived = !item.plan.archived;
    await ref
        .read(planRepositoryProvider)
        .setArchived(item.plan.id, nowArchived);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(nowArchived ? s.archivedMsg : s.unarchivedMsg),
          duration: const Duration(milliseconds: 1500)));
  }

  // ─── تب ایده‌ها (لیستِ صاف) ───────────────────────────────────────────────────

  Widget _buildIdeasTab(AppStrings s) {
    final async = ref.watch(ideasProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (ideas) {
        if (ideas.isEmpty) {
          return Center(
            child: Text(s.emptyIdeas,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.8)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: ideas.length,
          itemBuilder: (_, i) => _IdeaTile(
            idea: ideas[i],
            strings: s,
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => IdeaDetailScreen(idea: ideas[i])),
            ),
            onCycle: () =>
                ref.read(ideaRepositoryProvider).cycleStatus(ideas[i]),
            onActions: () => _ideaActions(ideas[i], s),
          ),
        );
      },
    );
  }

  Future<void> _addIdea(AppStrings s) async {
    final title = await _inputSheet(context, hint: s.newIdeaHint);
    if (title == null || title.trim().isEmpty) return;
    await ref.read(ideaRepositoryProvider).addIdea(title.trim());
  }

  // ─── شیتِ اکشن‌های ایده (۵ گزینه) ─────────────────────────────────────────────

  void _ideaActions(Task idea, AppStrings s) {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bolt, color: AppColors.accent),
              title: Text(s.convertToPlan,
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _ideaToNewPlan(idea, s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: Text(s.addToPlan),
              onTap: () {
                Navigator.pop(sheetCtx);
                _ideaToExistingPlan(idea, s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.today_outlined),
              title: Text(s.sendToToday),
              onTap: () {
                Navigator.pop(sheetCtx);
                _ideaToToday(idea, s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(s.scheduleToDay),
              onTap: () {
                Navigator.pop(sheetCtx);
                _ideaToSchedule(idea, s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(s.deleteLabel,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _deleteIdea(idea, s);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ۱) تبدیل به برنامهٔ جدید (با اسم و ایموجی)
  Future<void> _ideaToNewPlan(Task idea, AppStrings s) async {
    final res = await _planSheet(context, s, initialName: idea.title);
    if (res == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(ideaRepositoryProvider)
        .convertToPlan(idea, name: res.name, icon: res.icon);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(s.convertedMsg),
          duration: const Duration(milliseconds: 1500)));
  }

  // ۲) افزودن به یکی از برنامه‌های موجود (لیستِ اسکرولی، بدونِ بایگانی‌شده‌ها)
  Future<void> _ideaToExistingPlan(Task idea, AppStrings s) async {
    final plans = (ref.read(plansProvider).valueOrNull ?? const <Plan>[])
        .where((p) => !p.archived)
        .toList();
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(s.noPlansToPick),
            duration: const Duration(milliseconds: 1500)));
      return;
    }
    final picked = await showModalBottomSheet<Plan>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.pickPlan,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: plans.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Text(plans[i].icon ?? '📋',
                      style: const TextStyle(fontSize: 22)),
                  title: Text(plans[i].name),
                  onTap: () => Navigator.pop(sheetCtx, plans[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(ideaRepositoryProvider).addToPlan(idea, picked.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(s.addedToPlanMsg),
          duration: const Duration(milliseconds: 1500)));
  }

  // ۳) کارِ امروز
  Future<void> _ideaToToday(Task idea, AppStrings s) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(ideaRepositoryProvider).sendToDay(idea, DateTime.now());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(s.sentToTodayMsg),
          duration: const Duration(milliseconds: 1500)));
  }

  // ۴) تایمِ دیگه (اسکرولی)
  Future<void> _ideaToSchedule(Task idea, AppStrings s) async {
    final mode = ref.read(calendarModeProvider);
    final isFa = ref.read(localeProvider).languageCode == 'fa';
    final picked = await showWheelDateTime(context,
        initial: idea.dueDate ?? DateTime.now(), mode: mode, isFa: isFa);
    if (picked == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(ideaRepositoryProvider).sendToDay(idea, picked);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(s.scheduledMsg),
          duration: const Duration(milliseconds: 1500)));
  }

  // ۵) حذف
  Future<void> _deleteIdea(Task idea, AppStrings s) async {
    if (!await _confirmDelete(s)) return;
    await ref.read(ideaRepositoryProvider).deleteIdea(idea.id);
  }

  // ─── ابزارهای کمکی ───────────────────────────────────────────────────────────

  // شیتِ ساده برای افزودن/ویرایشِ ایده (فقط متن)
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

  // شیتِ برنامه (ایموجی + اسم)
  Future<({String name, String? icon})?> _planSheet(
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
              decoration: const InputDecoration(hintText: '📋'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(hintText: s.newPlanHint),
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

// مرتب‌سازی: سنجاق‌شده‌ها بالا → کامل‌نشده‌ها → کامل‌شده‌ها پایین
int _comparePlans(PlanWithProgress a, PlanWithProgress b) {
  if (a.plan.pinned != b.plan.pinned) return a.plan.pinned ? -1 : 1;
  if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
  return a.plan.orderKey.compareTo(b.plan.orderKey);
}

// ─── کارتِ برنامه (درشت + پیشرفت + بَج + سنجاق/بایگانی) ─────────────────────────

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.item,
    required this.strings,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleArchive,
  });
  final PlanWithProgress item;
  final AppStrings strings;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    final plan = item.plan;
    final completed = item.isCompleted;

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    // عقب‌افتاده = یا تاریخِ پایانِ خودِ برنامه گذشته، یا تسکِ عقب‌افتاده دارد
    final overdue = !completed &&
        ((plan.endDate != null && plan.endDate!.isBefore(startOfToday)) ||
            item.overdueCount > 0);

    return Opacity(
      opacity: plan.archived ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(plan.icon ?? '📋', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  if (plan.pinned) ...[
                    const Icon(Icons.push_pin,
                        size: 15, color: AppColors.accent),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                        color: completed
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (completed)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.check_circle,
                          size: 20, color: AppColors.green),
                    ),
                  if (item.dueCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        strings.number(item.dueCount),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz,
                        color: AppColors.textSecondary),
                    onSelected: (v) {
                      switch (v) {
                        case 'pin':
                          onTogglePin();
                          break;
                        case 'archive':
                          onToggleArchive();
                          break;
                        case 'rename':
                          onRename();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'pin',
                          child: Text(plan.pinned
                              ? strings.unpinLabel
                              : strings.pinLabel)),
                      PopupMenuItem(
                          value: 'archive',
                          child: Text(plan.archived
                              ? strings.unarchiveLabel
                              : strings.archiveLabel)),
                      PopupMenuItem(
                          value: 'rename', child: Text(strings.renameLabel)),
                      PopupMenuItem(
                          value: 'delete',
                          child: Text(strings.deleteLabel,
                              style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ]),
                if (overdue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline,
                          size: 13, color: AppColors.red),
                      const SizedBox(width: 4),
                      Text(strings.overdueLabel,
                          style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Text('${strings.number(item.remaining)} ${strings.remainingLabel}',
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(width: 10),
                  Text(
                      '${strings.number(item.done)}/${strings.number(item.total)} ${strings.doneLabel}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.progressTrack,
                    valueColor: AlwaysStoppedAnimation(
                        completed ? AppColors.green : AppColors.accent),
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

// ─── ردیفِ ایده ──────────────────────────────────────────────────────────────

class _IdeaTile extends StatelessWidget {
  const _IdeaTile({
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