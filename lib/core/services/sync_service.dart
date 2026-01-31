import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/schdules/data/models/task_model.dart';
import '../../features/schdules/data/models/default_task_model.dart';
import 'database_service.dart';

class SyncService {
  final DatabaseService databaseService;
  final SupabaseClient supabase;

  static const String lastSyncKey = 'last_sync_timestamp';
  bool _isSyncing = false; // Add lock flag

  SyncService({required this.databaseService, required this.supabase});

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> sync() async {
    try {
      if (!await _hasInternet()) {
        print("SyncService: No internet connection. Skipping sync.");
        return;
      }

      if (_isSyncing) {
        print("SyncService: Sync already in progress. Skipping.");
        return;
      }
      _isSyncing = true;

      final user = supabase.auth.currentUser;
      if (user == null) {
        print("SyncService: No user logged in. Skipping sync.");
        return;
      }

      final userId = user.id;
      final db = await databaseService.database;

      // Get last sync watermark
      final List<Map<String, dynamic>> settings = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [lastSyncKey],
      );

      final lastSyncStr = settings.isNotEmpty ? settings.first['value'] : null;
      final lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr).toUtc()
          : DateTime.fromMillisecondsSinceEpoch(0).toUtc();

      print(
        "SyncService: Starting optimized sync for user $userId. Last sync: $lastSync",
      );

      // --- 1. SYNC TASKS ---
      // 1.1 Pull remote changes (Remote -> Local)
      final remoteTasksData = await supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .gt('server_updated_at', lastSync.toIso8601String());

      final List<dynamic> remoteTasksList = remoteTasksData as List<dynamic>;
      int pulledTasksCount = 0;
      DateTime maxTaskWatermark = lastSync;

      for (final json in remoteTasksList) {
        final remoteTask = TaskModel.fromSupabaseJson(json);
        // Track the newest change from server
        if (remoteTask.serverUpdatedAt.isAfter(maxTaskWatermark)) {
          maxTaskWatermark = remoteTask.serverUpdatedAt;
        }

        // Check local state
        final List<Map<String, dynamic>> localMaps = await db.query(
          'tasks',
          where: 'id = ?',
          whereArgs: [remoteTask.id],
        );

        if (localMaps.isEmpty) {
          // New task from server, ensure is_dirty = 0
          await db.insert(
            'tasks',
            remoteTask.copyWith(isDirty: false).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          pulledTasksCount++;
        } else {
          final localTask = TaskModel.fromMap(localMaps.first);
          // Only update if server has a newer version
          if (remoteTask.serverUpdatedAt.isAfter(localTask.serverUpdatedAt)) {
            await db.update(
              'tasks',
              remoteTask.copyWith(isDirty: false).toMap(),
              where: 'id = ?',
              whereArgs: [remoteTask.id],
            );
            pulledTasksCount++;
          }
        }
      }

      // 1.2 Push local changes (Local -> Remote)
      final List<Map<String, dynamic>> localDirtyTasks = await db.query(
        'tasks',
        where: 'is_dirty = 1',
      );

      if (localDirtyTasks.isNotEmpty) {
        final tasksToPush = localDirtyTasks
            .map((m) => TaskModel.fromMap(m).toSupabaseJson(userId))
            .toList();

        await supabase.from('tasks').upsert(tasksToPush);

        // Clear is_dirty for pushed tasks
        await db.update(
          'tasks',
          {'is_dirty': 0},
          where:
              'id IN (${localDirtyTasks.map((e) => "'${e['id']}'").join(',')})',
        );
      }

      // --- 2. SYNC DEFAULT TASKS ---
      // 2.1 Pull remote changes
      final remoteDefaultTasksData = await supabase
          .from('default_tasks')
          .select()
          .eq('user_id', userId)
          .gt('server_updated_at', lastSync.toIso8601String());

      final List<dynamic> remoteDefaultTasksList =
          remoteDefaultTasksData as List<dynamic>;
      int pulledDefaultCount = 0;

      for (final json in remoteDefaultTasksList) {
        final remoteTask = DefaultTaskModel.fromSupabaseJson(json);
        if (remoteTask.serverUpdatedAt.isAfter(maxTaskWatermark)) {
          maxTaskWatermark = remoteTask.serverUpdatedAt;
        }

        final List<Map<String, dynamic>> localMaps = await db.query(
          'default_tasks',
          where: 'id = ?',
          whereArgs: [remoteTask.id],
        );

        if (localMaps.isEmpty) {
          await db.insert(
            'default_tasks',
            remoteTask.copyWith(isDirty: false).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          pulledDefaultCount++;
        } else {
          final localTask = DefaultTaskModel.fromMap(localMaps.first);
          if (remoteTask.serverUpdatedAt.isAfter(localTask.serverUpdatedAt)) {
            await db.update(
              'default_tasks',
              remoteTask.copyWith(isDirty: false).toMap(),
              where: 'id = ?',
              whereArgs: [remoteTask.id],
            );
            pulledDefaultCount++;
          }
        }
      }

      // 2.2 Push local changes
      final List<Map<String, dynamic>> localDirtyDefaults = await db.query(
        'default_tasks',
        where: 'is_dirty = 1',
      );

      if (localDirtyDefaults.isNotEmpty) {
        final defaultsToPush = localDirtyDefaults
            .map((m) => DefaultTaskModel.fromMap(m).toSupabaseJson(userId))
            .toList();

        await supabase.from('default_tasks').upsert(defaultsToPush);

        // Clear is_dirty
        await db.update(
          'default_tasks',
          {'is_dirty': 0},
          where:
              'id IN (${localDirtyDefaults.map((e) => "'${e['id']}'").join(',')})',
        );
      }

      // Update watermark to the newest data seen from server OR now if we pushed anything
      // Using maxTaskWatermark ensures we don't skip server changes even if clocks drift
      final newWatermark = maxTaskWatermark.toIso8601String();
      await db.insert('settings', {
        'key': lastSyncKey,
        'value': newWatermark,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      print(
        "SyncService: Sync completed. Pulled Tasks: $pulledTasksCount, Pulled Defaults: $pulledDefaultCount, Pushed Tasks: ${localDirtyTasks.length}",
      );
    } catch (e) {
      print("SyncService: Error during sync: $e");
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> fetchTasksForDateRange(DateTime start, DateTime end) async {
    try {
      if (!await _hasInternet()) return;

      final user = supabase.auth.currentUser;
      if (user == null) return;

      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      print("SyncService: Fetching tasks from $startStr to $endStr");

      final response = await supabase
          .from('tasks')
          .select()
          .eq('user_id', user.id)
          .gte('task_date', startStr)
          .lte('task_date', endStr);

      final remoteData = response as List<dynamic>;
      final db = await databaseService.database;

      for (final json in remoteData) {
        final remoteTask = TaskModel.fromSupabaseJson(json);
        await db.insert(
          'tasks',
          remoteTask.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      print("SyncService: Error fetching history: $e");
      rethrow;
    }
  }
}
