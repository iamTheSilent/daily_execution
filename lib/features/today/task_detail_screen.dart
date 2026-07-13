import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date/app_date.dart';
import '../../core/date/wheel_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/tables.dart';
import '../../providers/app_providers.dart';
import 'task_detail_controller.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskDetailProvider(taskId));
    final ctrl = ref.read(taskDetailProvider(taskId).notifier);
    final isFa = ref.watch(localeProvider).languageCode == 'fa';
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFa ? 'کار' : 'Task'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isFa ? 'تمام' : 'Done'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('${isFa ? 'خطا' : 'Error'}: $e')),
        data: (t) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: t.title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: isFa ? 'عنوان' : 'Title',
                hintStyle: TextStyle(color: p.textSecondary),
              ),
              onChanged: ctrl.setTitle,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                initialValue: t.note,
                maxLines: null,
                minLines: 4,
                style: TextStyle(color: p.textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: isFa ? 'یادداشت…' : 'Note…',
                  hintStyle: TextStyle(color: p.textSecondary),
                ),
                onChanged: ctrl.setNote,
              ),
            ),
            const SizedBox(height: 20),
            _label(isFa ? 'وضعیت' : 'Status', p),
            const SizedBox(height: 8),
            SegmentedButton<TaskStatus>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: TaskStatus.todo,
                    label: Text(isFa ? 'انجام‌نشده' : 'Todo')),
                ButtonSegment(
                    value: TaskStatus.doing,
                    label: Text(isFa ? 'در حال انجام' : 'Doing')),
                ButtonSegment(
                    value: TaskStatus.done,
                    label: Text(isFa ? 'انجام‌شده' : 'Done')),
              ],
              selected: {t.status},
              onSelectionChanged: (s) => ctrl.setStatus(s.first),
            ),
            const SizedBox(height: 16),
            _label(isFa ? 'اولویت' : 'Priority', p),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: ctrl.toggleFocus,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: t.focus ? p.accent : p.divider),
                  borderRadius: BorderRadius.circular(20),
                  color: t.focus
                      ? const Color(0x14FF9500)
                      : Colors.transparent,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star,
                      size: 16,
                      color: t.focus ? p.accent : p.textSecondary),
                  const SizedBox(width: 6),
                  Text(isFa ? 'فوکوس' : 'Focus',
                      style: TextStyle(
                          color: t.focus ? p.accent : p.textSecondary)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _label(isFa ? 'زمان' : 'Time', p),
            const SizedBox(height: 8),
            _TimeRow(
              label: isFa ? 'شروع' : 'Start',
              minutes: t.timeStart,
              isFa: isFa,
              onPick: (m) => ctrl.setTime(start: m, end: t.timeEnd),
              onClear: () => ctrl.setTime(start: null, end: t.timeEnd),
            ),
            _TimeRow(
              label: isFa ? 'پایان (اختیاری)' : 'End (optional)',
              minutes: t.timeEnd,
              isFa: isFa,
              onPick: (m) => ctrl.setTime(start: t.timeStart, end: m),
              onClear: () => ctrl.setTime(start: t.timeStart, end: null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, AppPalette p) => Text(
        text,
        style: TextStyle(fontSize: 13, color: p.textSecondary),
      );
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minutes,
    required this.isFa,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final int? minutes;
  final bool isFa;
  final ValueChanged<int> onPick;
  final VoidCallback onClear;

  String _fmt(int m) {
    final s =
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
    return isFa ? toFaDigits(s) : s;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: p.surface, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.access_time, color: p.textSecondary),
        title: Text(label, style: TextStyle(color: p.textPrimary)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(minutes == null ? '—' : _fmt(minutes!),
              style: TextStyle(color: p.textSecondary)),
          if (minutes != null)
            IconButton(
                icon: Icon(Icons.close, size: 18, color: p.textSecondary),
                onPressed: onClear),
        ]),
        onTap: () async {
          final picked = await showTimeWheel(
            context,
            initialMinutes: minutes ?? 540,
            isFa: isFa,
          );
          if (picked != null) onPick(picked);
        },
      ),
    );
  }
}
