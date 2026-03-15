import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../models/inbox_item_model.dart';
import 'inbox_local_data_source.dart';

class InboxLocalDataSourceImpl implements InboxLocalDataSource {
  final DatabaseService databaseService;

  InboxLocalDataSourceImpl({required this.databaseService});

  @override
  Future<void> insertInboxItem(InboxItemModel item) async {
    try {
      final db = await databaseService.database;
      await db.insert(
        'inbox_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<InboxItemModel>> getInboxItems() async {
    try {
      final db = await databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'inbox_items',
        where: 'is_deleted = 0',
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) => InboxItemModel.fromMap(maps[i]));
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> updateInboxItem(InboxItemModel item) async {
    try {
      final db = await databaseService.database;
      final count = await db.update(
        'inbox_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      if (count == 0) {
        throw CacheException('Inbox item not found');
      }
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteInboxItem(String id) async {
    try {
      final db = await databaseService.database;
      // Soft delete
      await db.update(
        'inbox_items',
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
