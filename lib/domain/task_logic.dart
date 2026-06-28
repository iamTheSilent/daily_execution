import '../data/database/database.dart';
import '../data/database/tables.dart';

TaskStatus nextStatus(TaskStatus s) => switch (s) {
      TaskStatus.todo => TaskStatus.doing,
      TaskStatus.doing => TaskStatus.done,
      TaskStatus.done => TaskStatus.todo,
    };

enum TaskSort { defaultSort, timeFirst, statusOrder, manual }

List<Task> sortDayTasks(List<Task> tasks, TaskSort sort) {
  final list = [...tasks];
  switch (sort) {
    case TaskSort.defaultSort:
      list.sort((a, b) {
        int rank(Task t) {
          if (t.status == TaskStatus.done) return 2;
          return t.focus ? 0 : 1;
        }
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.orderKey.compareTo(b.orderKey);
      });
    case TaskSort.timeFirst:
      list.sort((a, b) {
        if (a.timeStart == null && b.timeStart == null) return 0;
        if (a.timeStart == null) return 1;
        if (b.timeStart == null) return -1;
        return a.timeStart!.compareTo(b.timeStart!);
      });
    case TaskSort.statusOrder:
      list.sort((a, b) => a.status.index.compareTo(b.status.index));
    case TaskSort.manual:
      list.sort((a, b) => a.orderKey.compareTo(b.orderKey));
  }
  return list;
}