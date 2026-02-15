import 'package:equatable/equatable.dart';

class EnterpriseInfo extends Equatable {
  final List<String> databases;

  const EnterpriseInfo({
    required this.databases,
  });

  @override
  List<Object?> get props => [databases];
}
