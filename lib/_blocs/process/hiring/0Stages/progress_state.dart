import 'package:meta/meta.dart';

@immutable
class ProgressState {
  final bool loading;
  final bool approved;   // usado por selo local na página
  final bool completed;  // stage.completed
  final String? error;

  const ProgressState({
    this.loading = false,
    this.approved = false,
    this.completed = false,
    this.error,
  });

  factory ProgressState.initial() => const ProgressState();

  ProgressState copyWith({
    bool? loading,
    bool? approved,
    bool? completed,
    String? error,
  }) {
    return ProgressState(
      loading: loading ?? this.loading,
      approved: approved ?? this.approved,
      completed: completed ?? this.completed,
      error: error,
    );
  }
}
