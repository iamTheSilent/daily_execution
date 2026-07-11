import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/app_providers.dart';
import 'services/sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Shared container so the sync uses the same database as the app.
  final container = ProviderContainer();
  final sync = SyncService(container.read(databaseProvider));

  // Initial sync on startup, then every 2 minutes while the app is open.
  sync.syncNow();
  Timer.periodic(const Duration(minutes: 2), (_) => sync.syncNow());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DailyExecutionApp(),
    ),
  );
}