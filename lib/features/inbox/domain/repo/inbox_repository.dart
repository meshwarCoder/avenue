import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/inbox_item_model.dart';

abstract class InboxRepository {
  Future<Either<Failure, void>> addInboxItem(InboxItemModel item);
  Future<Either<Failure, List<InboxItemModel>>> getInboxItems();
  Future<Either<Failure, void>> updateInboxItem(InboxItemModel item);
  Future<Either<Failure, void>> deleteInboxItem(String id);
}
