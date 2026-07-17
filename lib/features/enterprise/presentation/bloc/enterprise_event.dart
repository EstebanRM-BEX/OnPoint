import 'package:equatable/equatable.dart';

abstract class EnterpriseEvent extends Equatable {
  const EnterpriseEvent();

  @override
  List<Object?> get props => [];
}

class SearchEnterpriseEvent extends EnterpriseEvent {
  final String url;

  const SearchEnterpriseEvent(this.url);

  @override
  List<Object?> get props => [url];
}

class GetRecentUrlsEvent extends EnterpriseEvent {
  const GetRecentUrlsEvent();
}

class DeleteRecentUrlEvent extends EnterpriseEvent {
  final String url;

  const DeleteRecentUrlEvent(this.url);

  @override
  List<Object?> get props => [url];
}

class SelectDatabaseEvent extends EnterpriseEvent {
  final String database;
  final String url;

  const SelectDatabaseEvent({required this.database, required this.url});

  @override
  List<Object?> get props => [database, url];
}
