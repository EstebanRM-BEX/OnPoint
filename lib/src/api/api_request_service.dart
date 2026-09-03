// ignore_for_file: unused_element, avoid_print, unrelated_type_equality_checks, unnecessary_string_interpolations, unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wms_app/core/network/connectivity_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wms_app/src/api/http_response_handler.dart';

import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/core/utils/widgets/dialog_loading_widget.dart';

class ApiRequestService {
  static final ApiRequestService _instance = ApiRequestService._internal();

  factory ApiRequestService() => _instance;

  ApiRequestService._internal();

  late String unencodePath;
  late HttpResponseHandler httpHandler;

  // Instancia reutilizada — evita crear un nuevo objeto en cada llamada
  final Connectivity _connectivity = Connectivity();

  void initialize({
    required String unencodePath,
    required HttpResponseHandler httpHandler,
  }) {
    this.unencodePath = unencodePath;
    this.httpHandler = httpHandler;
  }

  // ─── Helpers privados ────────────────────────────────────────────────────────

  /// Extrae el session_id de la cookie almacenada. Centraliza la lógica que
  /// antes estaba copy-paste en 10+ métodos.
  String _extractSessionId(String cookie) {
    for (final part in cookie.split(',')) {
      if (part.contains('session_id=')) {
        return part.split(';')[0].trim();
      }
    }
    return '';
  }

  /// Verifica conectividad local (WiFi / Mobile). No hace DNS lookup externo
  /// para no añadir latencia innecesaria a cada petición.
  Future<bool> _isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.isOnline;
  }

  /// Construye una respuesta sintética (no vino del servidor) con un cuerpo
  /// JSON-RPC válido.
  ///
  /// Antes se devolvía texto plano ('Error de red'). Varios repositorios
  /// parsean el body en errores con guards `statusCode <= 500` —necesario para
  /// leer los errores de Odoo, que llegan como HTTP 500 con body JSON, entre
  /// ellos la sesión expirada (code 100)— y ese texto plano reventaba el
  /// jsonDecode con FormatException, degradando el fallo a un modelo vacío
  /// sin mensaje.
  ///
  /// El `code` nunca es 100, así que no dispara el diálogo de sesión expirada.
  @visibleForTesting
  static http.Response buildClientErrorResponse(
    int statusCode,
    String message,
  ) {
    return http.Response(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': null,
        'error': {
          'code': statusCode,
          'message': message,
          'msg': message,
          'data': {'name': 'client_network_error', 'message': message},
        },
      }),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }

  void _showNetworkError() {
    // Evita el spam: varias peticiones fallando en ráfaga sin conexión
    // mostraban un snackbar de 5s por cada una.
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      'Error de red',
      'No se pudo conectar al servidor',
      backgroundColor: white,
      colorText: primaryColorApp,
      duration: const Duration(seconds: 5),
      leftBarIndicatorColor: yellow,
      icon: Icon(Icons.error, color: primaryColorApp),
    );
  }

  // ─── Métodos públicos ─────────────────────────────────────────────────────────

  Future<http.Response> post({
    required String endpoint,
    required Map<String, dynamic>? body,
    required bool isLoadinDialog,
    required bool isunecodePath,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [POST] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    url = url + (isunecodePath ? '$unencodePath/$endpoint' : '/$endpoint');
    final headers = {'Content-Type': 'application/json'};

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final response = await http
          .post(Uri.parse(url), body: jsonEncode(body), headers: headers)
          .timeout(const Duration(seconds: 100));

      if (isLoadinDialog) Get.back();

      if (response.headers.containsKey('set-cookie')) {
        await PrefUtils.setCookie(response.headers['set-cookie']!);
      }

      debugPrint('✅ POST $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [POST] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [POST] SocketException: $e');
      if (isLoadinDialog) Get.back();
      _showNetworkError();
      rethrow;
    } catch (e) {
      debugPrint('🔴 [POST] Error: $e');
      if (isLoadinDialog) Get.back();
      rethrow;
    }
  }

  Future<http.Response> searchEnterprice({required String enterprice}) async {
    final url = "$enterprice/web/database/list";

    if (!await _isConnected()) {
      debugPrint('🔴 [searchEnterprice] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({"params": {}}),
          )
          .timeout(const Duration(seconds: 100));
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [searchEnterprice] Timeout: $e');
      _showNetworkError();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [searchEnterprice] SocketException: $e');
      _showNetworkError();
      rethrow;
    } catch (e, s) {
      debugPrint('🔴 [searchEnterprice] Error: $e - $s');
      _showNetworkError();
      rethrow;
    }
  }

  Future<http.Response> postMultipartImage({
    required String endpoint,
    required File imageFile,
    required bool isLoadinDialog,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [postMultipartImage] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    const urlBase = 'https://apitemperature.360software.com.co';
    final fullUrl = Uri.parse('$urlBase/$endpoint');
    final ext = p.extension(imageFile.path).toLowerCase();
    final subtype = ext == '.png' ? 'png' : 'jpeg';

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.MultipartRequest('POST', fullUrl);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', subtype),
        ),
      );
      request.headers.addAll({'Accept': 'application/json'});

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ MULTIPART $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [postMultipartImage] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } catch (e, s) {
      if (isLoadinDialog) Get.back();
      debugPrint('🔴 [postMultipartImage] Error: $e\n$s');
      return buildClientErrorResponse(500, 'Error en la solicitud: $e');
    }
  }

  Future<http.Response> postMultipart({
    required String endpoint,
    required File imageFile,
    required int idMoveLine,
    required dynamic temperature,
    required bool isLoadinDialog,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [postMultipart] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    final urlBase = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final fullUrl = Uri.parse('$urlBase/api/$endpoint');
    final ext = p.extension(imageFile.path).toLowerCase();
    final subtype = ext == '.png' ? 'png' : 'jpeg';

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.MultipartRequest('POST', fullUrl);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image_data',
          imageFile.path,
          contentType: MediaType('image', subtype),
        ),
      );
      request.fields['move_line_id'] = idMoveLine.toString();
      request.fields['temperatura'] = temperature.toString();
      request.headers['Cookie'] = cookie;

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ MULTIPART $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [postMultipart] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } catch (e, s) {
      if (isLoadinDialog) Get.back();
      debugPrint('🔴 [postMultipart] Error: $e\n$s');
      return buildClientErrorResponse(500, 'Error en la solicitud: $e');
    }
  }

  Future<http.Response> postMultipartManual({
    required String endpoint,
    required int idMoveLine,
    required dynamic temperature,
    required bool isLoadinDialog,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [postMultipartManual] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    final urlBase = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final fullUrl = Uri.parse('$urlBase/api/$endpoint');

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.MultipartRequest('POST', fullUrl);
      request.fields['move_line_id'] = idMoveLine.toString();
      request.fields['temperatura'] = temperature.toString();
      request.headers['Cookie'] = cookie;

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ MULTIPART MANUAL $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [postMultipartManual] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } catch (e, s) {
      if (isLoadinDialog) Get.back();
      debugPrint('🔴 [postMultipartManual] Error: $e\n$s');
      return buildClientErrorResponse(500, 'Error en la solicitud: $e');
    }
  }

  Future<http.Response> postMultipartDynamic({
    required String endpoint,
    required File imageFile,
    required Map<String, dynamic> fields,
    bool isLoadingDialog = false,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [postMultipartDynamic] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    final urlBase = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final fullUrl = Uri.parse('$urlBase/api/$endpoint');
    final ext = p.extension(imageFile.path).toLowerCase();
    final subtype = ext == '.png' ? 'png' : 'jpeg';

    try {
      if (isLoadingDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.MultipartRequest('POST', fullUrl);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image_data',
          imageFile.path,
          contentType: MediaType('image', subtype),
        ),
      );
      fields.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      request.headers['Cookie'] = cookie;

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadingDialog) Get.back();
      debugPrint('✅ MULTIPART DYNAMIC $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [postMultipartDynamic] Timeout: $e');
      if (isLoadingDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } catch (e, s) {
      if (isLoadingDialog) Get.back();
      debugPrint('🔴 [postMultipartDynamic] Error: $e\n$s');
      return buildClientErrorResponse(500, 'Error en la solicitud: $e');
    }
  }

  Future<http.Response> postPicking({
    required String endpoint,
    required Map<String, dynamic>? body,
    required bool isLoadinDialog,
    required bool isunecodePath,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [postPicking] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);
    url = url + (isunecodePath ? '$unencodePath/$endpoint' : '/$endpoint');

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.Request('POST', Uri.parse(url));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      final streamed = await request.send().timeout(
        const Duration(seconds: 100),
      );
      final response = await http.Response.fromStream(streamed);

      if (isLoadinDialog) Get.back();
      debugPrint('✅ POST PICKING $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [postPicking] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [postPicking] SocketException: $e');
      if (isLoadinDialog) Get.back();
      _showNetworkError();
      rethrow;
    } catch (e, s) {
      debugPrint('🔴 [postPicking] Error: $e\n$s');
      if (isLoadinDialog) Get.back();
      rethrow;
    }
  }

  /// [showNetworkErrorSnackbar]: si es false, no muestra el snackbar global
  /// "No se pudo conectar al servidor". Lo usan los flujos que manejan la
  /// falta de conexión por su cuenta (ej. validación offline de expedición,
  /// que valida local y encola el envío) para no confundir al operario con un
  /// error cuando la acción sí se completó localmente.
  Future<http.Response> postPacking({
    required String endpoint,
    required Map<String, dynamic>? body,
    required bool isLoadinDialog,
    bool showNetworkErrorSnackbar = true,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [postPacking] Sin conexión');
      if (showNetworkErrorSnackbar) _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);
    url = '$url$unencodePath/$endpoint';

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    bool loadingDialogOpened = false;
    try {
      if (isLoadinDialog) {
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );
        loadingDialogOpened = true;
      }

      final request = http.Request('POST', Uri.parse(url));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      // Sin timeout el diálogo de carga se quedaba abierto para siempre si el
      // servidor no respondía. Mismo límite que postPicking.
      final streamed = await request.send().timeout(
        const Duration(seconds: 100),
      );
      final response = await http.Response.fromStream(streamed);

      if (loadingDialogOpened) {
        Get.back();
        loadingDialogOpened = false;
      }

      debugPrint('✅ POST PACKING $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [postPacking] Timeout: $e');
      if (loadingDialogOpened) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [postPacking] SocketException: $e');
      if (loadingDialogOpened) Get.back();
      if (showNetworkErrorSnackbar) _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    } catch (e) {
      debugPrint('🔴 [postPacking] Error: $e');
      if (loadingDialogOpened) Get.back();
      rethrow;
    }
  }

  Future<http.Response> postPrint({
    required String endpoint,
    required Map<String, dynamic>? body,
    required bool isLoadinDialog,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [postPrint] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);
    url = '$url/$endpoint';

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    bool loadingDialogOpened = false;
    try {
      if (isLoadinDialog) {
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );
        loadingDialogOpened = true;
      }

      final request = http.Request('POST', Uri.parse(url));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      // Sin timeout el diálogo de carga se quedaba abierto para siempre si el
      // servidor de impresión no respondía. Mismo límite que postPacking.
      final streamed = await request.send().timeout(
        const Duration(seconds: 100),
      );
      final response = await http.Response.fromStream(streamed);

      if (loadingDialogOpened) {
        Get.back();
        loadingDialogOpened = false;
      }

      debugPrint('✅ POST PRINT $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [postPrint] Timeout: $e');
      if (loadingDialogOpened) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud de impresión superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [postPrint] SocketException: $e');
      if (loadingDialogOpened) Get.back();
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    } catch (e) {
      debugPrint('🔴 [postPrint] Error: $e');
      if (loadingDialogOpened) Get.back();
      rethrow;
    }
  }

  Future<http.Response> getInfo({
    required String endpoint,
    required Map<String, dynamic>? body,
    required bool isLoadinDialog,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [getInfo] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);
    url = '$url$unencodePath/$endpoint';

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.Request('GET', Uri.parse(url));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ GET INFO $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [getInfo] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [getInfo] SocketException: $e');
      if (isLoadinDialog) Get.back();
      _showNetworkError();
      rethrow;
    } catch (e) {
      debugPrint('🔴 [getInfo] Error: $e');
      if (isLoadinDialog) Get.back();
      rethrow;
    }
  }

  Future<http.Response> get({
    required String endpoint,
    required bool isLoadinDialog,
    required bool isunecodePath,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [GET] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);

    if (sessionId.isEmpty) {
      debugPrint('🔴 [GET] Session ID vacío');
      return buildClientErrorResponse(404, 'Error de red');
    }

    url = url + (isunecodePath ? '$unencodePath/$endpoint' : '/$endpoint');

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.Request('GET', Uri.parse(url));
      request.body = json.encode({"params": {}});
      request.headers.addAll(headers);

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ GET $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [GET] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [GET] SocketException: $e');
      if (isLoadinDialog) Get.back();
      _showNetworkError();
      rethrow;
    } catch (e) {
      debugPrint('🔴 [GET] Error: $e');
      if (isLoadinDialog) Get.back();
      rethrow;
    }
  }

  Future<http.Response> getValidation({
    required String endpoint,
    required bool isLoadinDialog,
    required bool isunecodePath,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [getValidation] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);

    if (sessionId.isEmpty) {
      debugPrint('🔴 [getValidation] Session ID vacío');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final mac = await PrefUtils.getMacPDA();
    final imei = await PrefUtils.getImeiPDA();

    url = url + (isunecodePath ? '$unencodePath/$endpoint' : '/$endpoint');

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.Request('GET', Uri.parse(url));
      request.body = json.encode({
        "params": {
          "device_id": mac == "02:00:00:00:00:00" ? imei : mac,
          "version_app": packageInfo.version,
        },
      });
      request.headers.addAll(headers);

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ GET VALIDATION $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [getValidation] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [getValidation] SocketException: $e');
      if (isLoadinDialog) Get.back();
      _showNetworkError();
      rethrow;
    } catch (e) {
      debugPrint('🔴 [getValidation] Error: $e');
      if (isLoadinDialog) Get.back();
      rethrow;
    }
  }

  Future<Uint8List?> fetchImageBytesFromProtectedUrl({
    required String fullImageUrl,
    bool isLoadinDialog = false,
  }) async {
    if (!await _isConnected()) {
      _showNetworkError();
      return null;
    }

    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);

    if (sessionId.isEmpty) {
      Get.snackbar(
        'Error de sesión',
        'No se pudo obtener la sesión de usuario',
        backgroundColor: white,
        colorText: primaryColorApp,
        duration: const Duration(seconds: 5),
        leftBarIndicatorColor: yellow,
        icon: Icon(Icons.error, color: primaryColorApp),
      );
      return null;
    }

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: 'view_image'),
          barrierDismissible: false,
        );

      final request = http.Request('GET', Uri.parse(fullImageUrl));
      request.headers['Cookie'] = sessionId;
      // Forzar PNG/JPEG para garantizar compatibilidad con Android ImageDecoder
      request.headers['Accept'] = 'image/png, image/jpeg, image/*;q=0.8';

      final streamed = await request.send().timeout(
        const Duration(seconds: 100),
      );

      if (isLoadinDialog) Get.back();

      final contentType = streamed.headers['content-type'] ?? '';

      if (streamed.statusCode == 200) {
        // Si el servidor devuelve HTML (ej. página de login) en lugar de imagen, descartar
        if (contentType.contains('text/html')) {
          Get.snackbar(
            'Error',
            'No se pudo autenticar para cargar la imagen',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.lock_outline, color: Colors.red),
          );
          return null;
        }
        final bytes = await streamed.stream.toBytes();
        return bytes;
      } else {
        debugPrint('🔴 [fetchImage] Status: ${streamed.statusCode}');
        Get.snackbar(
          'Error',
          'No se pudo cargar la imagen (${streamed.statusCode})',
          backgroundColor: white,
          colorText: primaryColorApp,
          duration: const Duration(seconds: 5),
          icon: Icon(Icons.error_outline, color: primaryColorApp),
        );
        return null;
      }
    } on TimeoutException catch (e) {
      if (isLoadinDialog) Get.back();
      debugPrint('🔴 [fetchImage] Timeout: $e');
      Get.snackbar(
        'Error',
        'La imagen tardó demasiado en cargar',
        backgroundColor: white,
        colorText: primaryColorApp,
        duration: const Duration(seconds: 5),
        icon: Icon(Icons.error_outline, color: primaryColorApp),
      );
      return null;
    } catch (e) {
      if (isLoadinDialog) Get.back();
      debugPrint('🔴 [fetchImage] Error: $e');
      Get.snackbar(
        'Error inesperado',
        'Ocurrió un error al cargar la imagen',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: Icon(Icons.error, color: primaryColorApp),
      );
      return null;
    }
  }

  Future<http.Response> getInventario({
    required String endpoint,
    required bool isLoadinDialog,
    required bool isunecodePath,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [getInventario] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);

    if (sessionId.isEmpty) {
      debugPrint('🔴 [getInventario] Session ID vacío');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    url = url + (isunecodePath ? '/op$unencodePath/$endpoint' : '/$endpoint');

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.Request('GET', Uri.parse(url));
      request.body = json.encode({"params": {}});
      request.headers.addAll(headers);

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ GET INVENTARIO $endpoint → ${response.statusCode}');
      return response;
    } on SocketException catch (e) {
      debugPrint('🔴 [getInventario] SocketException: $e');
      if (isLoadinDialog) Get.back();
      _showNetworkError();
      rethrow;
    } catch (e) {
      debugPrint('🔴 [getInventario] Error: $e');
      if (isLoadinDialog) Get.back();
      rethrow;
    }
  }

  Future<http.Response> postInventario({
    required String endpoint,
    required bool isLoadinDialog,
    required bool isunecodePath,
    required Map<String, dynamic>? body,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [postInventario] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);

    if (sessionId.isEmpty) {
      debugPrint('🔴 [postInventario] Session ID vacío');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    url = url + (isunecodePath ? '/op$unencodePath/$endpoint' : '/$endpoint');

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.Request('GET', Uri.parse(url));
      request.body = json.encode(body);
      request.headers.addAll(headers);

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ POST INVENTARIO $endpoint → ${response.statusCode}');
      return response;
    } on SocketException catch (e) {
      debugPrint('🔴 [postInventario] SocketException: $e');
      if (isLoadinDialog) Get.back();
      _showNetworkError();
      rethrow;
    } catch (e) {
      debugPrint('🔴 [postInventario] Error: $e');
      if (isLoadinDialog) Get.back();
      rethrow;
    }
  }

  Future<http.Response> getHistory({
    required String endpoint,
    required bool isLoadinDialog,
    required bool isunecodePath,
    required String field,
    required String date,
  }) async {
    if (!await _isConnected()) {
      debugPrint('🔴 [getHistory] Sin conexión');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    var url = await PrefUtils.getEnterprise();
    final cookie = await PrefUtils.getCookie();
    final sessionId = _extractSessionId(cookie);

    if (sessionId.isEmpty) {
      debugPrint('🔴 [getHistory] Session ID vacío');
      _showNetworkError();
      return buildClientErrorResponse(404, 'Error de red');
    }

    url = url + (isunecodePath ? '$unencodePath/$endpoint' : '/$endpoint');

    final headers = {'Content-Type': 'application/json', 'Cookie': sessionId};

    try {
      if (isLoadinDialog)
        Get.dialog(
          DialogLoadingNetwork(titel: endpoint),
          barrierDismissible: false,
        );

      final request = http.Request('GET', Uri.parse(url));
      request.body = json.encode({
        "params": {"$field": "$date"},
      });
      request.headers.addAll(headers);

      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 100)),
      );

      if (isLoadinDialog) Get.back();
      debugPrint('✅ GET HISTORY $endpoint → ${response.statusCode}');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('🔴 [getHistory] Timeout: $e');
      if (isLoadinDialog) Get.back();
      return buildClientErrorResponse(
        408,
        'La solicitud superó el tiempo de espera',
      );
    } on SocketException catch (e) {
      debugPrint('🔴 [getHistory] SocketException: $e');
      if (isLoadinDialog) Get.back();
      _showNetworkError();
      rethrow;
    } catch (e) {
      debugPrint('🔴 [getHistory] Error: $e');
      if (isLoadinDialog) Get.back();
      rethrow;
    }
  }
}
