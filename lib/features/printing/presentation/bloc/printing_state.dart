part of 'printing_bloc.dart';

abstract class PrintingState extends Equatable {
  const PrintingState();

  @override
  List<Object?> get props => [];
}

class PrintingInitial extends PrintingState {}

class PrintersLoading extends PrintingState {}

class PrintersLoaded extends PrintingState {
  final List<Printer> printers;
  const PrintersLoaded(this.printers);

  @override
  List<Object?> get props => [printers];
}

class PrintersError extends PrintingState {
  final String message;
  const PrintersError(this.message);

  @override
  List<Object?> get props => [message];
}

class PrintingInProgress extends PrintingState {}

class PrintSuccess extends PrintingState {
  final String message;
  final List<Printer> printers;
  const PrintSuccess(this.message, this.printers);

  @override
  List<Object?> get props => [message, printers];
}

class PrintError extends PrintingState {
  final String message;
  const PrintError(this.message);

  @override
  List<Object?> get props => [message];
}
