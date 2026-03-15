import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/inbox_local_data_source.dart';
import '../models/inbox_item_model.dart';
import '../../domain/repo/inbox_repository.dart';

class InboxRepositoryImpl implements InboxRepository {
  final InboxLocalDataSource localDataSource;

  InboxRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, void>> addInboxItem(InboxItemModel item) async {
    try {
      await localDataSource.insertInboxItem(item);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<InboxItemModel>>> getInboxItems() async {
    try {
      final result = await localDataSource.getInboxItems();
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateInboxItem(InboxItemModel item) async {
    try {
      await localDataSource.updateInboxItem(item);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInboxItem(String id) async {
    try {
      await localDataSource.deleteInboxItem(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
