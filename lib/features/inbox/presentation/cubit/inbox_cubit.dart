import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/inbox_item_model.dart';
import '../../domain/repo/inbox_repository.dart';
import 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final InboxRepository repository;

  InboxCubit({required this.repository}) : super(InboxInitial());

  Future<void> loadInboxItems() async {
    emit(InboxLoading());
    final result = await repository.getInboxItems();
    result.fold(
      (failure) => emit(InboxError(failure.message)),
      (items) => emit(InboxLoaded(items)),
    );
  }

  Future<void> addInboxItem(InboxItemModel item) async {
    emit(InboxLoading());
    final result = await repository.addInboxItem(item);
    result.fold(
      (failure) => emit(InboxError(failure.message)),
      (_) => loadInboxItems(),
    );
  }

  Future<void> updateInboxItem(InboxItemModel item) async {
    emit(InboxLoading());
    final result = await repository.updateInboxItem(item);
    result.fold(
      (failure) => emit(InboxError(failure.message)),
      (_) => loadInboxItems(),
    );
  }

  Future<void> deleteInboxItem(String id) async {
    emit(InboxLoading());
    final result = await repository.deleteInboxItem(id);
    result.fold(
      (failure) => emit(InboxError(failure.message)),
      (_) => loadInboxItems(),
    );
  }
}
