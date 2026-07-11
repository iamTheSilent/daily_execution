import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/database/database.dart';
import '../data/database/tables.dart';

// Server address.
// - Testing with Chrome on this same laptop: keep 127.0.0.1.
// - Testing on a phone on the same wifi: change to the laptop LAN IP,
//   e.g. 'http://192.168.1.5:8787'.
// - Production: the VPS address.
const String kServerBaseUrl = 'http://127.0.0.1:8787';

class SyncService {
  SyncService(this._db);
  final AppDatabase _db;

  bool _busy = false;

  Future<bool> syncNow() async {
    if (_busy) return false;
    _busy = true;
    try {
      final allTasks = await _db.select(_db.tasks).get();

      final tasksPayload = <Map<String, dynamic>>[];
      final ideasPayload = <Map<String, dynamic>>[];

      for (final t in allTasks) {
        // All ideas -> for the 72h nudge.
        if (t.bucket == TaskBucket.idea) {
          ideasPayload.add({
            'id': t.id,
            'title': t.title,
            'createdAt': t.createdAt.toUtc().toIso8601String(),
          });
        }

        // Compute the exact due datetime for time-bound tasks.
        DateTime? dueAt;
        if (t.dueDate != null) {
          // Plan tasks with a due date + scheduled ideas.
          dueAt = t.dueDate;
        } else if (t.bucket == TaskBucket.day &&
            t.day != null &&
            t.timeStart != null) {
          // Today tasks with a specific time (timeStart = minutes from midnight).
          final d = t.day!;
          dueAt = DateTime(
            d.year,
            d.month,
            d.day,
            t.timeStart! ~/ 60,
            t.timeStart! % 60,
          );
        }

        if (dueAt != null) {
          tasksPayload.add({
            'id': t.id,
            'title': t.title,
            'dueAt': dueAt.toUtc().toIso8601String(),
            'done': t.status == TaskStatus.done,
          });
        }
      }

      final resp = await http
          .post(
            Uri.parse('$kServerBaseUrl/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tasks': tasksPayload,
              'ideas': ideasPayload,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      // Server offline / no network: just skip this round.
      return false;
    } finally {
      _busy = false;
    }
  }
}