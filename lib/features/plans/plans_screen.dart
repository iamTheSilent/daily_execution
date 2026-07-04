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
            onRename: () => _editPlan(plans[i], s),
            onDelete: () => _deletePlan(plans[i], s),
          ),
        );
      },
    );
  }

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

  // ۲) افزودن به یکی از برنامه‌های موجود (لیستِ اسکرولی)
  Future<void> _ideaToExistingPlan(Task idea, AppStrings s) async {
    final plans = ref.read(plansProvider).valueOrNull ?? const <Plan>[];
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

// ─── کارتِ برنامه (درشت + پراگرس‌بار + ایموجی) ──────────────────────────────────

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
                Text(plan.icon ?? '📋', style: const TextStyle(fontSize: 22)),
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
                        color: AppColors.accent,
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
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
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