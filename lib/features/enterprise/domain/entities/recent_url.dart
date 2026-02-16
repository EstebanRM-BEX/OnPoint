import 'package:equatable/equatable.dart';

class RecentUrl extends Equatable {
  final int? id;
  final String url;
  final DateTime fecha;

  const RecentUrl({
    this.id,
    required this.url,
    required this.fecha,
  });

  @override
  List<Object?> get props => [id, url, fecha];
}
