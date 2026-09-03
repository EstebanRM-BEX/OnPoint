// ignore_for_file: avoid_print, unnecessary_null_comparison, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/main.dart'; // IMPORTANTE: Importar para acceder a navigatorKey
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class HttpResponseHandler {
  HttpResponseHandler();

  BuildContext? get context => navigatorKey.currentContext;

  // Evita apilar varios diálogos si llegan varios 401 casi juntos (ej. la
  // racha de llamadas seguidas al validar un cluster: reenviar pendientes →
  // validar pedido → guardar campo → cerrar batch — si la sesión ya expiró,
  // cada una devuelve 401).
  bool _unauthorizedDialogVisible = false;
  Future handleHttpResponse(Future<Response> httpCall) async {
    var response = await httpCall;
    debugPrint('handleHttpResponse: ${response.statusCode}');
    switch (response.statusCode) {
      case 200:
        return response;
      case 201:
        return response;
      case 204:
        return response;
      case 400:
        _handle400(response);
        return response;
      case 401:
        _handleUnauthorized(response);
        return response;

      case 422:
        _handle422(response);
        return response;
      case 440:
      // throw UnauthorizedException(response.body);
      default:
        var message = jsonDecode(response.body)["message"];
        _showErrorSnackBar([message]);
    }
  }

  /// 401: la cookie de sesión de Odoo ya no es válida (expiró o se
  /// invalidó en el servidor). NO cerramos sesión ni navegamos solos —
  /// el operario puede estar en medio de un proceso (ej. validando un
  /// cluster) y sacarlo de la pantalla sin aviso es peor que dejarlo ver
  /// el error. Solo se informa; si quiere volver a iniciar sesión lo hace
  /// manualmente desde el menú de usuario.
  void _handleUnauthorized(Response response) {
    if (_unauthorizedDialogVisible) return;

    String detalle = 'Tu sesión no es válida o expiró.';
    try {
      final body = jsonDecode(response.body);
      final backendMessage = body is Map
          ? (body['message'] ?? body['error'])
          : null;
      if (backendMessage != null && backendMessage.toString().isNotEmpty) {
        detalle = '$detalle\n\n$backendMessage';
      }
    } catch (_) {
      // Cuerpo no es JSON o no trae mensaje — nos quedamos con el genérico.
    }

    _unauthorizedDialogVisible = true;
    showScrollableErrorDialog(
      detalle,
    ).whenComplete(() => _unauthorizedDialogVisible = false);
  }

  _handle422(Response response) {
    // var message = jsonDecode(response.body)["message"];
    Map<String, dynamic> errors = jsonDecode(response.body)["errors"];
    var errorList = <String>[];

    var t = errors.values.map((e) => e as List<dynamic>);
    for (var element in t) {
      for (var e in element) {
        errorList.add(e as String);
      }
    }
    _showErrorSnackBar(errorList);
  }

  _handle400(Response response) {
    var message = jsonDecode(response.body)["data"];
    debugPrint('handle400: $message');
    _showErrorSnackBar([message]);
  }

  void _showErrorSnackBar(List<String> errorList) {
    final snackBar = SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: errorList.map((error) => Text(error)).toList(),
      ),
      backgroundColor: primaryColorApp,
      behavior: SnackBarBehavior.floating,
    );
    if (context != null) {
      ScaffoldMessenger.of(context!).showSnackBar(snackBar);
    }
  }
}
