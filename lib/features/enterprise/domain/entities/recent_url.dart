import 'package:equatable/equatable.dart';

class RecentUrl extends Equatable {
  final int? id;
  final String url;
  final DateTime date;

  const RecentUrl({
    this.id,
    required this.url,
    required this.date,
  });

  @override
  List<Object?> get props => [id, url, date];
}
