import 'dart:convert';
import 'package:injectable/injectable.dart';

import 'package:wms_app/src/api/api_request_service.dart';
import '../../models/packaging_type_model.dart';

abstract class PackagingTypeRemoteDataSource {
  Future<List<PackagingTypeModel>> getPackagingTypes();
}

@LazySingleton(as: PackagingTypeRemoteDataSource)
class PackagingTypeRemoteDataSourceImpl implements PackagingTypeRemoteDataSource {
  final ApiRequestService apiRequestService;

  PackagingTypeRemoteDataSourceImpl(this.apiRequestService);

  @override
  Future<List<PackagingTypeModel>> getPackagingTypes() async {
    final response = await apiRequestService.get(
      endpoint: 'api/get_packaging_types',
      isLoadinDialog: false,
      isunecodePath: false,
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      
      // JSON-RPC format parsing based on the provided sample
      if (jsonResponse.containsKey('result') && jsonResponse['result'] is Map) {
        final resultData = jsonResponse['result'];
        if (resultData['code'] == 200 && resultData['result'] is List) {
          final List dynamicList = resultData['result'];
          return dynamicList
              .map((item) => PackagingTypeModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } else {
      throw Exception('Failed to load packaging types: ${response.statusCode}');
    }
  }
}
