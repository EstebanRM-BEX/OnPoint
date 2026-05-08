import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:wms_app/core/error/failures.dart';
import '../../../../src/api/api_request_service.dart';
import '../../domain/entities/printer.dart';
import '../../domain/repositories/printing_repository.dart';
import '../models/printer_model.dart';

@LazySingleton(as: PrintingRepository)
class PrintingRepositoryImpl implements PrintingRepository {
  final ApiRequestService apiService;

  PrintingRepositoryImpl({required this.apiService});

  @override
  Future<Either<Failure, List<Printer>>> getPrinters() async {
    try {
      final response = await apiService.postPacking(
        endpoint: 'printer_details',
        // isunecodePath: true,
        body: {},
        isLoadinDialog: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['result'];

        if (result != null && result['code'] == 200) {
          final List<dynamic> printerList = result['result'];
          final printers = printerList
              .map((e) => PrinterModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return Right(printers);
        } else {
          return Left(
              ServerFailure(result?['msg'] ?? 'Error al obtener impresoras'));
        }
      } else {
        return Left(ServerFailure('Error de servidor: ${response.statusCode}'));
      }
    } catch (e, s) {
      debugPrint('Error en getPrinters: $e, $s');
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> printReport({
    required int printerId,
    required String name,
    required String reportName,
    required String model,
    required int resId,
    required int companyId,
    required int userId,
    int copies = 1,
  }) async {
    try {
      final response = await apiService.postPrint(
        endpoint: 'direct-print/print-report',
        isLoadinDialog: true,
        body: {
          "jsonrpc": "2.0",
          "method": "call",
          "params": {
            "action": {
              "type": "ir.actions.report",
              "nameEE": name,
              "report_name": reportName,
              "context": {
                "active_model": model,
                "active_ids": [resId],
                "active_id": resId,
                "allowed_company_ids": [companyId],
                "printer_id": printerId
              }
            },
            "options": {},
            "sticker_quantity": copies,
            "user_id": userId,
          }
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('error') &&
            jsonResponse['error'] != null) {
          final error = jsonResponse['error'];
          final message = error is Map
              ? (error['data']?['message'] ?? error['message'])
              : 'Error del servidor Odoo';
          return Left(
              ServerFailure(message?.toString() ?? 'Error del servidor Odoo'));
        }

        final result = jsonResponse['result'];

        if (result == true || (result is Map && result['success'] == true)) {
          return const Right(true);
        } else {
          final message = result is Map ? result['message'] : null;
          final msg = result is Map ? result['msg'] : null;
          return Left(
              ServerFailure(message?.toString() ?? 'Error al imprimir: $msg'));
        }
      } else {
        return Left(ServerFailure('Error de servidor: ${response.statusCode}'));
      }
    } catch (e, s) {
      debugPrint('Error en printReport: $e, $s');
      return Left(ServerFailure('Error inesperado: $e'));
    }
  }
}
