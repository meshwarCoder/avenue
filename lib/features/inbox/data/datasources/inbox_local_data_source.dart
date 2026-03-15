import '../models/inbox_item_model.dart';

abstract class InboxLocalDataSource {
  Future<void> insertInboxItem(InboxItemModel item);
  Future<List<InboxItemModel>> getInboxItems();
  Future<void> updateInboxItem(InboxItemModel item);
  Future<void> deleteInboxItem(String id);
}
