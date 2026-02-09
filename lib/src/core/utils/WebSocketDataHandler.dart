import 'dart:convert';
import 'package:wms_app/src/services/webSocket_service.dart';

class WebSocketDataHandler {
  final WebSocketService _socketService = WebSocketService(); // Usamos el Singleton
  
  // Aquí inyectarías tus repositorios de base de datos local
  // final ProductsRepository _productsRepo = ProductsRepository();

  /// Inicializa la escucha. Llámalo en el main o al iniciar sesión.
  void initialize() {
    print("🎧 Handler: Escuchando eventos del WebSocket...");
    
    _socketService.messages.listen((dynamic data) {
      _processIncomingData(data);
    });
  }

  void _processIncomingData(dynamic rawData) async {
    try {
      // 1. Decodificar
      if (rawData is String) {
        rawData = jsonDecode(rawData);
      }
      
      final Map<String, dynamic> message = rawData;

      // 2. Validar estructura básica
      if (!message.containsKey('model') || !message.containsKey('action')) {
        return; // No es un mensaje de datos (puede ser el 'subscribe_success')
      }

      final String model = message['model'];
      final String action = message['action'];
      final Map<String, dynamic> payload = message['data'] ?? {};

      print("⚡ Evento recibido: Modelo [$model] -> Acción [$action]");

      // 3. ENRUTADOR (Switch principal)
      switch (model) {
        case 'products_quants':
          await _handleProductQuant(action, payload);
          break;
          
        case 'stock_picking':
          await _handleStockPicking(action, payload);
          break;
          
        case 'res_partner':
          // await _handlePartner(action, payload);
          break;

        default:
          print("⚠️ Modelo desconocido: $model");
      }

    } catch (e) {
      print("❌ Error procesando data del socket: $e");
    }
  }

  // --- MÉTODOS ESPECÍFICOS POR MÓDULO ---

  Future<void> _handleProductQuant(String action, Map<String, dynamic> data) async {
    // Aquí llamas a tu Base de Datos Local (SQLite / Drift / Hive)
    
    switch (action) {
      case 'create':
      case 'update': // A veces 'add' y 'update' se manejan igual (upsert)
        print("📥 Actualizando producto en BD Local: ${data['id']}");
        // await _productsRepo.insertOrUpdate(data);
        break;

      case 'delete':
      case 'unlink':
        print("🗑️ Eliminando producto de BD Local: ${data['id']}");
        // await _productsRepo.deleteById(data['id']);
        break;
    }
  }

  Future<void> _handleStockPicking(String action, Map<String, dynamic> data) async {
    // Lógica para recepciones/transferencias
    if (action == 'update') {
      // Actualizar estado de la orden
    }
  }
}