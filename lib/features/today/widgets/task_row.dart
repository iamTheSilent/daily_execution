import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables.dart';

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.onCycleStatus,
    required this.onOpen,
  });

  final Task task;
  final VoidCallback onCycleStatus;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    final isDoing = task.status == TaskStatus.doing;
    final bg = isDone
        ? AppColors.doneBg
        : (task.focus ? AppColors.focusTint : AppColors.surface);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onCycleStatus,
                  behavior: HitTestBehavior.opaque,
                  child: _StatusRing(isDone: isDone, isDoing: isDoing),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (task.timeStart != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          _formatTime(task.timeStart, task.timeEnd),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int? start, int? end) {
    String fmt(int m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
    if (start == null) return '';
    if (end == null) return fmt(start);
    return '${fmt(start)}–${fmt(end)}';
  }
}

class _StatusRing extends StatelessWidget {
  const _StatusRing({required this.isDone, required this.isDoing});
  final bool isDone;
  final bool isDoing;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return const Icon(Icons.check_circle, color: AppColors.green, size: 26);
    }
    if (isDoing) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          value: 0.75,
          color: AppColors.accent,
          backgroundColor: AppColors.progressTrack,
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textSecondary, width: 2),
      ),
    );
  }
}