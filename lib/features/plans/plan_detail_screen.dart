import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/date/app_date.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';

const _accent = Color(0xFFFF9500);

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
        backgroundColor: _accent,
        onPressed: () => _addTask(context, ref, s),
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (tasks) {
          final done = tasks.where((t) => t.status == TaskStatus.done).length;
          final total = tasks.length;
          final remaining = total - done;
          final progress = total == 0 ? 0.0 : done / total;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('$remaining ${s.remainingLabel}',
                          style: const TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(width: 12),
                      Text('$done/$total ${s.doneLabel}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(_accent),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(s.emptyPlanTasks,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: isFa ? 'تسکِ جدید…' : 'New task…'),
                onSubmitted: (_) => Navigator.pop(sheetCtx, true),
              ),
              const SizedBox(height: 8),
              Row(children: [
                TextButton.icon(
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(due == null
                      ? s.addTime
                      : AppDate.secondaryShort(
                          due!, ref.read(calendarModeProvider))),
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDatePicker(
                      context: sheetCtx,
                      initialDate: due ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (d != null) setSheet(() => due = d);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => Navigator.pop(sheetCtx, true),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(planRepositoryProvider).createPlanTask(
            planId: plan.id,
            title: ctrl.text.trim(),
            dueDate: due,
          );
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: overdue
            ? const BorderSide(color: Colors.red, width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              _StatusCircle(status: task.status, onTap: onToggle),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        style: TextStyle(
                          fontSize: 16,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          color: done ? Colors.grey : null,
                        )),
                    if (task.note != null && task.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(task.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              if (overdue)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 20),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.grey,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({required this.status, required this.onTap});
  final TaskStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    Color color;
    switch (status) {
      case TaskStatus.todo:
        icon = null;
        color = Colors.grey;
        break;
      case TaskStatus.doing:
        icon = Icons.timelapse;
        color = _accent;
        break;
      case TaskStatus.done:
        icon = Icons.check;
        color = Colors.green;
        break;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          color: status == TaskStatus.done ? Colors.green : Colors.transparent,
        ),
        child: icon == null
            ? null
            : Icon(icon,
                size: 16,
                color: status == TaskStatus.done ? Colors.white : color),
      ),
    );
  }
}

// ─── صفحهٔ جزئیاتِ مشترکِ تسک (فعلاً همین‌جا؛ بعداً برای «امروز» جداش می‌کنیم) ───

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
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );
    setState(() {
      _dueDate = DateTime(
          date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
    });
  }

  String _clock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return toFaDigits('$h:$m');
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
              tooltip: s.deleteLabel,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete),
          IconButton(
              tooltip: s.saveLabel,
              icon: const Icon(Icons.check),
              onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: isFa ? 'عنوان' : 'Title',
            ),
          ),
          const SizedBox(height: 12),
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
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 22),
          ],
          _label(isFa ? 'توضیحات' : 'Notes'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _noteCtrl,
              maxLines: null,
              minLines: 4,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: s.noteHint,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _label(isFa ? 'زمان' : 'Time'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: Colors.grey.withOpacity(0.08),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(_dueDate == null
                  ? s.addTime
                  : AppDate.primaryLong(_dueDate!, mode)),
              subtitle: _dueDate == null ? null : Text(_clock(_dueDate!)),
              trailing: _dueDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
              onTap: _pickDateTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: const TextStyle(color: Colors.grey, fontSize: 13));
}