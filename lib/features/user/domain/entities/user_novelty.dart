import 'package:equatable/equatable.dart';

class Novedad extends Equatable {
  final int id;
  final String name;
  final String code;

  const Novedad({
    required this.id,
    required this.name,
    required this.code,
  });

  @override
  List<Object> get props => [id, name, code];
}
