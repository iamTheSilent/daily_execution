import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/date/app_date.dart';
import '../../core/date/wheel_picker.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final tasksAsync = ref.watch(planTasksProvider(plan.id));

    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context, ref, s),
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tasks) {
          final done = tasks.where((t) => t.status == TaskStatus.done).length;
          final total = tasks.length;
          final progress = total == 0 ? 0.0 : done / total;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('${total - done} ${s.remainingLabel}',
                          style: TextStyle(
                              color: context.palette.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(width: 10),
                      Text('$done/$total ${s.doneLabel}',
                          style: TextStyle(
                              color: context.palette.textSecondary, fontSize: 14)),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: context.palette.progressTrack,
                        valueColor:
                            AlwaysStoppedAnimation(context.palette.accent),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(s.emptyPlanTasks,
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: context.palette.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        itemCount: tasks.length,
                        itemBuilder: (_, i) => _PlanTaskCard(
                          task: tasks[i],
                          onToggle: () => ref
                              .read(planRepositoryProvider)
                              .cyclePlanTaskStatus(tasks[i]),
                          onOpen: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    TaskDetailScreen(task: tasks[i])),
                          ),
                          onDelete: () => ref
                              .read(planRepositoryProvider)
                              .deletePlanTask(tasks[i].id),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addTask(
      BuildContext context, WidgetRef ref, AppStrings s) async {
    final isFa = ref.read(localeProvider).languageCode == 'fa';
    final ctrl = TextEditingController();
    DateTime? due;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: isFa ? 'تسکِ جدید…' : 'New task…'),
                onSubmitted: (_) => Navigator.pop(sheetCtx, true),
              ),
              Row(children: [
                TextButton.icon(
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(due == null
                      ? s.addTime
                      : AppDate.secondaryShort(
                          due!, ref.read(calendarModeProvider),
                          faDigits: isFa)),
                  onPressed: () async {
                    final d = await showWheelDateTime(sheetCtx,
                        initial: due,
                        mode: ref.read(calendarModeProvider),
                        isFa: isFa);
                    if (d != null) setSheet(() => due = d);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => Navigator.pop(sheetCtx, true),
                ),
              ]),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref
          .read(planRepositoryProvider)
          .createPlanTask(planId: plan.id, title: ctrl.text.trim(), dueDate: due);
    }
  }
}

class _PlanTaskCard extends StatelessWidget {
  const _PlanTaskCard({
    required this.task,
    required this.onToggle,
    required this.onOpen,
    required this.onDelete,
  });
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.done;
    final now = DateTime.now();
    final overdue = !done &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: done ? context.palette.doneBg : context.palette.surface,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          onTap: onOpen,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
              border: overdue
                  ? Border.all(color: context.palette.red, width: 1.2)
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: _StatusCircle(status: task.status),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            color: done
                                ? context.palette.textSecondary
                                : context.palette.textPrimary,
                          )),
                      if (task.note != null && task.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(task.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.palette.textSecondary, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                if (overdue)
                  Icon(Icons.warning_amber_rounded,
                      color: context.palette.red, size: 20),
              ],
            ),
          ),
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
    if (status == TaskStatus.done) {
      return Icon(Icons.check_circle, color: context.palette.green, size: 26);
    }
    if (status == TaskStatus.doing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          value: null, // چرخشی (بی‌نهایت) به‌جای ثابت
          color: context.palette.accent,
          backgroundColor: context.palette.progressTrack,
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.palette.textSecondary, width: 2),
      ),
    );
  }
}

// ─── جزئیاتِ مشترکِ تسک (با انتخابگرِ چرخشی) ───

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.task});
  final Task task;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  DateTime? _dueDate;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _noteCtrl = TextEditingController(text: widget.task.note ?? '');
    _dueDate = widget.task.dueDate;
    _status = widget.task.status;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final note = _noteCtrl.text.trim();
    await ref.read(databaseProvider).updateTaskFields(
          widget.task.id,
          TasksCompanion(
            title: Value(title),
            note: Value(note.isEmpty ? null : note),
            dueDate: Value(_dueDate),
            status: Value(_status),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).deleteTask(widget.task.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickDateTime() async {
    final isFa = ref.read(localeProvider).languageCode == 'fa';
    final picked = await showWheelDateTime(
      context,
      initial: _dueDate,
      mode: ref.read(calendarModeProvider),
      isFa: isFa,
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  String _clock(DateTime dt) {
    final isFa = ref.read(localeProvider).languageCode == 'fa';
    final t = '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
    return isFa ? toFaDigits(t) : t;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final mode = ref.watch(calendarModeProvider);
    final isFa = ref.read(localeProvider).languageCode == 'fa';
    final isIdea = widget.task.bucket == TaskBucket.idea;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFa ? 'جزئیات' : 'Details'),
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: _delete),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleCtrl,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
                border: InputBorder.none, hintText: isFa ? 'عنوان' : 'Title'),
          ),
          const SizedBox(height: 16),
          if (!isIdea) ...[
            _label(isFa ? 'وضعیت' : 'Status'),
            const SizedBox(height: 8),
            SegmentedButton<TaskStatus>(
              segments: [
                ButtonSegment(
                    value: TaskStatus.todo,
                    label: Text(isFa ? 'مونده' : 'To do')),
                ButtonSegment(
                    value: TaskStatus.doing,
                    label: Text(isFa ? 'در حال' : 'Doing')),
                ButtonSegment(
                    value: TaskStatus.done,
                    label: Text(isFa ? 'انجام‌شده' : 'Done')),
              ],
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 22),
          ],
          _label(isFa ? 'توضیحات' : 'Notes'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _noteCtrl,
              maxLines: null,
              minLines: 4,
              decoration:
                  InputDecoration(border: InputBorder.none, hintText: s.noteHint),
            ),
          ),
          const SizedBox(height: 22),
          _label(isFa ? 'زمان' : 'Time'),
          const SizedBox(height: 8),
          Material(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: const Icon(Icons.schedule),
              title: Text(_dueDate == null
                  ? s.addTime
                  : AppDate.primaryLong(_dueDate!, mode, faDigits: isFa)),
              subtitle: _dueDate == null ? null : Text(_clock(_dueDate!)),
              trailing: _dueDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
              onTap: _pickDateTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(color: context.palette.textSecondary, fontSize: 13));
}