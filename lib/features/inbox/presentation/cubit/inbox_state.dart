import '../../data/models/inbox_item_model.dart';

abstract class InboxState {}

class InboxInitial extends InboxState {}

class InboxLoading extends InboxState {}

class InboxLoaded extends InboxState {
  final List<InboxItemModel> items;
  InboxLoaded(this.items);
}

class InboxError extends InboxState {
  final String message;
  InboxError(this.message);
}
