import 'package:equatable/equatable.dart';

/// A one-shot message (snackbar) carried in bloc state.
///
/// Every instance gets a unique [id], so emitting the same text twice still
/// counts as a new message for `listenWhen` comparisons.
class UiMessage extends Equatable {
  UiMessage(this.text, {this.isError = false}) : id = _nextId++;

  static int _nextId = 0;

  final String text;
  final bool isError;
  final int id;

  @override
  List<Object?> get props => [id, text, isError];
}
