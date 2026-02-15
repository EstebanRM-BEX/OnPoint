import 'package:equatable/equatable.dart';
import '../../domain/entities/enterprise_info.dart';
import '../../domain/entities/recent_url.dart';

abstract class EnterpriseState extends Equatable {
  const EnterpriseState();

  @override
  List<Object?> get props => [];
}

class EnterpriseInitial extends EnterpriseState {}

class EnterpriseLoading extends EnterpriseState {}

class EnterpriseSuccess extends EnterpriseState {
  final EnterpriseInfo enterpriseInfo;
  final String url;

  const EnterpriseSuccess({required this.enterpriseInfo, required this.url});

  @override
  List<Object?> get props => [enterpriseInfo, url];
}

class EnterpriseFailure extends EnterpriseState {
  final String message;

  const EnterpriseFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class RecentUrlsLoaded extends EnterpriseState {
  final List<RecentUrl> recentUrls;

  const RecentUrlsLoaded(this.recentUrls);

  @override
  List<Object?> get props => [recentUrls];
}

class DatabaseSelectedState extends EnterpriseState {
  final String database;
  final String url;

  const DatabaseSelectedState({required this.database, required this.url});

  @override
  List<Object?> get props => [database, url];
}
