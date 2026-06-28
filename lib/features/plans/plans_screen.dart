import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';
import 'idea_detail_screen.dart';
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
    final plansAsync = ref.watch(plansProvider);
    final ideasAsync = ref.watch(ideasProvider);

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
          _buildPlansTab(s, plansAsync),
          _buildIdeasTab(s, ideasAsync),
        ],
      ),
    );
  }

  // ─── تب برنامه‌ها ────────────────────────────────────────────────────────────

  Widget _buildPlansTab(AppStrings s, AsyncValue<List<Plan>> async) {
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

  // ─── تب ایده‌ها ──────────────────────────────────────────────────────────────

  Widget _buildIdeasTab(AppStrings s, AsyncValue<List<Task>> async) {
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
            onConvert: () => _convertToPlan(ideas[i], s),
            onSendToday: () => _sendToToday(ideas[i], s),
            onDelete: () => _deleteIdea(ideas[i], s),
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

  Future<void> _convertToPlan(Task idea, AppStrings s) async {
    await ref.read(ideaRepositoryProvider).convertToPlan(idea);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(s.convertedMsg),
      duration: const Duration(milliseconds: 1500),
      action: SnackBarAction(
        label: s.viewLabel,
        onPressed: () {
          messenger.hideCurrentSnackBar();
          setState(() => _tab = 0);
        },
      ),
    ));
  }

  Future<void> _sendToToday(Task idea, AppStrings s) async {
    await ref.read(ideaRepositoryProvider).sendToDay(idea, DateTime.now());
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(s.sentToTodayMsg),
      duration: const Duration(milliseconds: 1500),
    ));
  }

  Future<void> _deleteIdea(Task idea, AppStrings s) async {
    if (!await _confirmDelete(s)) return;
    await ref.read(ideaRepositoryProvider).deleteIdea(idea.id);
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

// ─── کارتِ ایده ─────────────────────────────────────────────────────────────────

class _IdeaTile extends StatelessWidget {
  const _IdeaTile({
    required this.idea,
    required this.strings,
    required this.onOpen,
    required this.onConvert,
    required this.onSendToday,
    required this.onDelete,
  });
  final Task idea;
  final AppStrings strings;
  final VoidCallback onOpen;
  final VoidCallback onConvert;
  final VoidCallback onSendToday;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onOpen,
        leading: const Icon(Icons.lightbulb_outline),
        title: Text(idea.title),
        subtitle: idea.note == null || idea.note!.isEmpty
            ? null
            : Text(idea.note!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'convert') onConvert();
            if (v == 'today') onSendToday();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'convert',
                child: Row(children: [
                  const Icon(Icons.upgrade, size: 18),
                  const SizedBox(width: 8),
                  Text(strings.convertToPlan),
                ])),
            PopupMenuItem(
                value: 'today',
                child: Row(children: [
                  const Icon(Icons.today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(strings.sendToToday),
                ])),
            PopupMenuItem(
                value: 'delete',
                child: Text(strings.deleteLabel,
                    style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}