import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../src/api/api_request_service.dart';
import '../models/enterprise_model.dart';

abstract class EnterpriseRemoteDataSource {
  Future<EnterpriseModel> searchEnterprise(String url);
}

@LazySingleton(as: EnterpriseRemoteDataSource)
class EnterpriseRemoteDataSourceImpl implements EnterpriseRemoteDataSource {
  final ApiRequestService apiService;

  EnterpriseRemoteDataSourceImpl(this.apiService);

  @override
  Future<EnterpriseModel> searchEnterprise(String url) async {
    final response = await apiService.searchEnterprice(enterprice: url);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = json.decode(response.body);
      // The API returns { "result": ["db1", "db2"] }
      final List<dynamic> databases = data['result'] ?? [];
      return EnterpriseModel(
          databases: databases.map((e) => e.toString()).toList());
    } else {
      throw Exception('Failed to load enterprises');
    }
  }
}
