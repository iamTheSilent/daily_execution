import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/date/app_date.dart';
import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';

/// صفحهٔ جزئیاتِ مشترک برای هر تسک (امروز / برنامه / ایده)
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

  bool get _isFa => ref.read(localeProvider).languageCode == 'fa';

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
    final mode = ref.watch(calendarModeProvider);
    final isFa = _isFa;
    final isIdea = widget.task.bucket == TaskBucket.idea;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFa ? 'جزئیات' : 'Details'),
        actions: [
          IconButton(
              tooltip: isFa ? 'حذف' : 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete),
          IconButton(
              tooltip: isFa ? 'ذخیره' : 'Save',
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

          // وضعیت (برای ایده نمایش داده نمی‌شه)
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
              onSelectionChanged: (s) => setState(() => _status = s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 22),
          ],

          // توضیحات (اول)
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
                hintText: isFa ? 'یادداشت…' : 'Write a note…',
              ),
            ),
          ),
          const SizedBox(height: 22),

          // زمان (بعد)
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
                  ? (isFa ? 'افزودن زمان' : 'Add time')
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