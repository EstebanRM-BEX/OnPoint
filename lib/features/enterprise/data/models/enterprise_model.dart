import 'package:wms_app/features/enterprise/domain/entities/enterprise_info.dart';

class EnterpriseModel extends EnterpriseInfo {
  const EnterpriseModel({
    required super.databases,
  });

  factory EnterpriseModel.fromJson(Map<String, dynamic> json) {
    return EnterpriseModel(
      databases: (json['databases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'databases': databases,
    };
  }
}
