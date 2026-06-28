import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/tables.dart';
import 'task_detail_controller.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskDetailProvider(taskId));
    final ctrl = ref.read(taskDetailProvider(taskId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done')),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (t) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: t.title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: 'Title'),
              onChanged: ctrl.setTitle,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                initialValue: t.note,
                maxLines: null,
                minLines: 4,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Note…'),
                onChanged: ctrl.setNote,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Status',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            SegmentedButton<TaskStatus>(
              segments: const [
                ButtonSegment(
                    value: TaskStatus.todo, label: Text('Todo')),
                ButtonSegment(
                    value: TaskStatus.doing, label: Text('Doing')),
                ButtonSegment(
                    value: TaskStatus.done, label: Text('Done')),
              ],
              selected: {t.status},
              onSelectionChanged: (s) => ctrl.setStatus(s.first),
            ),
            const SizedBox(height: 16),
            const Text('Priority',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: ctrl.toggleFocus,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: t.focus
                          ? const Color(0xFFFF9500)
                          : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                  color: t.focus
                      ? const Color(0x14FF9500)
                      : Colors.transparent,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star,
                      size: 16,
                      color: t.focus
                          ? const Color(0xFFFF9500)
                          : Colors.grey),
                  const SizedBox(width: 6),
                  Text('Focus',
                      style: TextStyle(
                          color: t.focus
                              ? const Color(0xFFFF9500)
                              : Colors.grey)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Time',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            _TimeRow(
              label: 'Start',
              minutes: t.timeStart,
              onPick: (m) => ctrl.setTime(start: m, end: t.timeEnd),
              onClear: () => ctrl.setTime(start: null, end: t.timeEnd),
            ),
            _TimeRow(
              label: 'End (optional)',
              minutes: t.timeEnd,
              onPick: (m) => ctrl.setTime(start: t.timeStart, end: m),
              onClear: () =>
                  ctrl.setTime(start: t.timeStart, end: null),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minutes,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final int? minutes;
  final ValueChanged<int> onPick;
  final VoidCallback onClear;

  String _fmt(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text(label),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(minutes == null ? '—' : _fmt(minutes!)),
          if (minutes != null)
            IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear),
        ]),
        onTap: () => _pickTime(context),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final h = (minutes ?? 540) ~/ 60;
    final m = (minutes ?? 0) % 60;
    await showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 250,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: DateTime(2000, 1, 1, h, m),
          use24hFormat: true,
          onDateTimeChanged: (d) => onPick(d.hour * 60 + d.minute),
        ),
      ),
    );
  }
}