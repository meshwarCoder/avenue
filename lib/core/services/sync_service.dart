import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/schdules/data/models/task_model.dart';
import '../../features/schdules/data/models/default_task_model.dart';
import 'database_service.dart';
import '../../features/auth/domain/repo/auth_repository.dart';
import 'device_service.dart';
import '../utils/observability.dart';
import 'task_notification_manager.dart';
import '../../features/inbox/data/models/inbox_item_model.dart';

class SyncService {
  final DatabaseService databaseService;
  final SupabaseClient supabase;
  final AuthRepository authRepository;
  final DeviceService deviceService;
  final TaskNotificationManager notificationManager;

  static const String lastSyncKey = 'last_sync_timestamp';
  bool _isSyncing = false; // Add lock flag

  SyncService({
    required this.databaseService,
    required this.supabase,
    required this.authRepository,
    required this.deviceService,
    required this.notificationManager,
  });

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> syncAll() async {
    try {
      if (!await _hasInternet()) {
        AvenueLogger.log(
          event: 'SYNC_SKIPPED',
          layer: LoggerLayer.SYNC,
          payload: 'No internet',
        );
        return;
      }

      if (_isSyncing) {
        AvenueLogger.log(
          event: 'SYNC_SKIPPED',
          layer: LoggerLayer.SYNC,
          payload: 'Already in progress',
        );
        return;
      }
      _isSyncing = true;

      final user = supabase.auth.currentUser;
      if (user == null) {
        AvenueLogger.log(
          event: 'SYNC_SKIPPED',
          layer: LoggerLayer.SYNC,
          payload: 'No user',
        );
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

      AvenueLogger.log(
        event: 'SYNC_STARTED',
        layer: LoggerLayer.SYNC,
        payload: {'userId': userId, 'lastSync': lastSync.toIso8601String()},
      );

      // --- 1. SYNC TASKS ---
      final maxTaskWatermark = await _syncTasks(userId, db, lastSync);

      // --- 2. SYNC DEFAULT TASKS ---
      final maxDefaultWatermark = await _syncDefaultTasks(userId, db, lastSync);

      // --- 3. SYNC INBOX ITEMS (Two-Way) ---
      await _syncInboxItems(userId, db);
      await _downloadInboxItems(userId, db);

      // Update watermark to the newest data seen from server
      DateTime finalWatermark = maxTaskWatermark;
      if (maxDefaultWatermark.isAfter(finalWatermark)) {
        finalWatermark = maxDefaultWatermark;
      }

      final newWatermarkStr = finalWatermark.toIso8601String();
      await db.insert('settings', {
        'key': lastSyncKey,
        'value': newWatermarkStr,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // --- 4. REFRESH DEVICE ACTIVITY ---
      try {
        final deviceId = await deviceService.getDeviceId();
        await authRepository.updateDeviceSyncTimestamp(deviceId);
      } catch (e) {
        AvenueLogger.log(
          event: 'SYNC_DEVICE_UPDATE_FAILED',
          level: LoggerLevel.WARN,
          layer: LoggerLayer.SYNC,
          payload: e.toString(),
        );
      }

      AvenueLogger.log(
        event: 'SYNC_COMPLETED',
        layer: LoggerLayer.SYNC,
        payload: {'lastSync': newWatermarkStr},
      );
    } catch (e) {
      AvenueLogger.log(
        event: 'SYNC_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.SYNC,
        payload: e.toString(),
      );
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<DateTime> _syncTasks(
    String userId,
    Database db,
    DateTime lastSync,
  ) async {
    // 1.1 Pull remote changes (Remote -> Local)
    AvenueLogger.log(
      event: 'DB_READ',
      layer: LoggerLayer.SYNC,
      payload: {
        'source': 'SUPABASE',
        'entity': 'tasks',
        'lastSync': lastSync.toIso8601String(),
      },
    );
    final remoteTasksData = await supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .gt('server_updated_at', lastSync.toIso8601String());

    final List<dynamic> remoteTasksList = remoteTasksData as List<dynamic>;
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
        // New task from server: schedule notifications
        await notificationManager.updateTaskNotificationIfNeeded(
          null,
          remoteTask,
        );
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
          // Updated task from server: check if notifications need updating
          await notificationManager.updateTaskNotificationIfNeeded(
            localTask,
            remoteTask,
          );
        }
      }
    }

    // 1.2 Push local changes (Local -> Remote)
    final List<Map<String, dynamic>> localDirtyTasks = await db.query(
      'tasks',
      where: 'is_dirty = 1',
    );

    if (localDirtyTasks.isNotEmpty) {
      final tasksToPush = <Map<String, dynamic>>[];
      for (final m in localDirtyTasks) {
        final task = TaskModel.fromMap(m);
        tasksToPush.add(task.toSupabaseJson(userId));
      }

      AvenueLogger.log(
        event: 'DB_UPSERT',
        layer: LoggerLayer.SYNC,
        payload: {
          'source': 'SUPABASE',
          'entity': 'tasks',
          'count': tasksToPush.length,
        },
      );
      await supabase.from('tasks').upsert(tasksToPush);

      // Clear is_dirty for pushed tasks
      await db.update(
        'tasks',
        {'is_dirty': 0},
        where:
            'id IN (${localDirtyTasks.map((e) => "'${e['id']}'").join(',')})',
      );
    }

    return maxTaskWatermark;
  }

  Future<DateTime> _syncDefaultTasks(
    String userId,
    Database db,
    DateTime lastSync,
  ) async {
    // 2.1 Pull remote changes
    final remoteDefaultTasksData = await supabase
        .from('default_tasks')
        .select()
        .eq('user_id', userId)
        .gt('server_updated_at', lastSync.toIso8601String());

    final List<dynamic> remoteDefaultTasksList =
        remoteDefaultTasksData as List<dynamic>;
    DateTime maxDefaultWatermark = lastSync;

    for (final json in remoteDefaultTasksList) {
      final remoteTask = DefaultTaskModel.fromSupabaseJson(json);
      if (remoteTask.serverUpdatedAt.isAfter(maxDefaultWatermark)) {
        maxDefaultWatermark = remoteTask.serverUpdatedAt;
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
      } else {
        final localTask = DefaultTaskModel.fromMap(localMaps.first);
        if (remoteTask.serverUpdatedAt.isAfter(localTask.serverUpdatedAt)) {
          await db.update(
            'default_tasks',
            remoteTask.copyWith(isDirty: false).toMap(),
            where: 'id = ?',
            whereArgs: [remoteTask.id],
          );
        }
      }
    }

    // 2.2 Push local changes
    final List<Map<String, dynamic>> localDirtyDefaults = await db.query(
      'default_tasks',
      where: 'is_dirty = 1',
    );

    if (localDirtyDefaults.isNotEmpty) {
      final defaultsToPush = <Map<String, dynamic>>[];
      for (final m in localDirtyDefaults) {
        final task = DefaultTaskModel.fromMap(m);
        defaultsToPush.add(task.toSupabaseJson(userId));
      }

      await supabase.from('default_tasks').upsert(defaultsToPush);

      // Clear is_dirty
      await db.update(
        'default_tasks',
        {'is_dirty': 0},
        where:
            'id IN (${localDirtyDefaults.map((e) => "'${e['id']}'").join(',')})',
      );
    }

    return maxDefaultWatermark;
  }

  Future<void> _syncInboxItems(String userId, Database db) async {
    final List<Map<String, dynamic>> localDirtyInbox = await db.query(
      'inbox_items',
      where: 'is_dirty = 1',
    );

    if (localDirtyInbox.isNotEmpty) {
      final authUserId = supabase.auth.currentUser?.id;
      AvenueLogger.log(
        event: 'SYNC_INBOX_UPLOAD_DEBUG',
        layer: LoggerLayer.SYNC,
        payload: {
          'count': localDirtyInbox.length,
          'authUserId': authUserId,
          'methodUserId': userId,
        },
      );

      try {
        final inboxToPush = <Map<String, dynamic>>[];
        for (final m in localDirtyInbox) {
          final item = InboxItemModel.fromMap(m);
          final supabaseJson = item.toSupabaseJson(userId);

          AvenueLogger.log(
            event: 'SYNC_INBOX_ITEM_DATA',
            layer: LoggerLayer.SYNC,
            payload: {
              'id': item.id,
              'sendingUserId': supabaseJson['user_id'],
              'match': supabaseJson['user_id'] == authUserId,
            },
          );
          inboxToPush.add(supabaseJson);
        }

        AvenueLogger.log(
          event: 'SYNC_INBOX_UPLOAD_STARTED',
          layer: LoggerLayer.SYNC,
          payload: {'count': localDirtyInbox.length},
        );

        final response = await supabase.from('inbox_items').upsert(inboxToPush).select();

        AvenueLogger.log(
          event: 'SYNC_INBOX_UPLOAD_SUCCESS',
          layer: LoggerLayer.SYNC,
          payload: {
            'count': localDirtyInbox.length,
            'response': response,
          },
        );

        // Clear is_dirty and set server_updated_at locally
        final now = DateTime.now().toUtc().toIso8601String();
        await db.update(
          'inbox_items',
          {'is_dirty': 0, 'server_updated_at': now},
          where:
              'id IN (${localDirtyInbox.map((e) => "'${e['id']}'").join(',')})',
        );
      } catch (e) {
        AvenueLogger.log(
          event: 'SYNC_INBOX_UPLOAD_ERROR',
          level: LoggerLevel.ERROR,
          layer: LoggerLayer.SYNC,
          payload: {
            'error': e.toString(),
            'details': e is PostgrestException ? e.details : null,
            'message': e is PostgrestException ? e.message : null,
            'hint': e is PostgrestException ? e.hint : null,
            'code': e is PostgrestException ? e.code : null,
          },
        );
        rethrow;
      }
    }
  }

  Future<void> _downloadInboxItems(String userId, Database db) async {
    AvenueLogger.log(
      event: 'SYNC_INBOX_DOWNLOAD_STARTED',
      layer: LoggerLayer.SYNC,
      payload: {'userId': userId},
    );

    try {
      final remoteInboxData = await supabase
          .from('inbox_items')
          .select()
          .eq('user_id', userId);

      final List<dynamic> remoteInboxList = remoteInboxData as List<dynamic>;

      for (final json in remoteInboxList) {
        final remoteItem = InboxItemModel.fromSupabaseJson(json);

        // Check local state
        final List<Map<String, dynamic>> localMaps = await db.query(
          'inbox_items',
          where: 'id = ?',
          whereArgs: [remoteItem.id],
        );

        if (localMaps.isEmpty) {
          // New item from server
          await db.insert(
            'inbox_items',
            remoteItem.copyWith(isDirty: false).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          final localItem = InboxItemModel.fromMap(localMaps.first);

          final remoteTime = remoteItem.serverUpdatedAt;
          final localTime = localItem.serverUpdatedAt;

          bool shouldUpdate = false;
          if (remoteTime == null) {
            // If server_updated_at is null -> treat server as newer
            shouldUpdate = true;
          } else if (localTime == null || remoteTime.isAfter(localTime)) {
            // Fallback to updated_at comparison if both non-null, or if local is null
            shouldUpdate = true;
          }

          if (shouldUpdate) {
            AvenueLogger.log(
              event: 'SYNC',
              layer: LoggerLayer.SYNC,
              payload: 'updating item from server: ${remoteItem.id}',
            );
            await db.update(
              'inbox_items',
              remoteItem.copyWith(isDirty: false).toMap(),
              where: 'id = ?',
              whereArgs: [remoteItem.id],
            );
          } else {
            AvenueLogger.log(
              event: 'SYNC',
              layer: LoggerLayer.SYNC,
              payload: 'skipping item: ${remoteItem.id}',
            );
          }
        }
      }

      AvenueLogger.log(
        event: 'SYNC_INBOX_MERGE_COMPLETED',
        layer: LoggerLayer.SYNC,
      );
    } catch (e) {
      AvenueLogger.log(
        event: 'SYNC_INBOX_DOWNLOAD_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.SYNC,
        payload: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> fetchTasksForDateRange(DateTime start, DateTime end) async {
    try {
      if (!await _hasInternet()) return;

      final user = supabase.auth.currentUser;
      if (user == null) return;

      final startStr = start.toIso8601String().split('T')[0];
      final endStr = end.toIso8601String().split('T')[0];

      AvenueLogger.log(
        event: 'SYNC_FETCH_RANGE',
        layer: LoggerLayer.SYNC,
        payload: {'start': startStr, 'end': endStr},
      );

      AvenueLogger.log(
        event: 'DB_READ',
        layer: LoggerLayer.SYNC,
        payload: {
          'source': 'SUPABASE',
          'entity': 'tasks_range',
          'start': startStr,
          'end': endStr,
        },
      );
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
      AvenueLogger.log(
        event: 'SYNC_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.SYNC,
        payload: e.toString(),
      );
      rethrow;
    }
  }
}
