import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date/app_date.dart';
import '../../data/database/database.dart';
import '../../providers/app_providers.dart';

class IdeaDetailScreen extends ConsumerStatefulWidget {
  const IdeaDetailScreen({super.key, required this.idea});
  final Task idea;

  @override
  ConsumerState<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends ConsumerState<IdeaDetailScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.idea.title);
    _noteCtrl = TextEditingController(text: widget.idea.note ?? '');
    _scheduledAt = widget.idea.dueDate;
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
    await ref.read(ideaRepositoryProvider).updateIdea(
          widget.idea.id,
          title: title,
          note: _noteCtrl.text.trim(),
          scheduledAt: _scheduledAt,
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );
    setState(() {
      _scheduledAt = DateTime(
        date.year, date.month, date.day,
        time?.hour ?? 0, time?.minute ?? 0,
      );
    });
  }

  String _timeText(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return toFaDigits('$h:$m');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final mode = ref.watch(calendarModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.ideaDetailTitle),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: s.newIdeaHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: null,
            minLines: 5,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: s.noteHint,
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(_scheduledAt == null
                ? s.addTime
                : AppDate.primaryLong(_scheduledAt!, mode)),
            subtitle:
                _scheduledAt == null ? null : Text(_timeText(_scheduledAt!)),
            trailing: _scheduledAt == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _scheduledAt = null),
                  ),
            onTap: _pickTime,
          ),
        ],
      ),
    );
  }
}