// app_routes.dart

import 'package:flutter/material.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/features/expedition/presentation/screens/expedition_screen.dart';
import 'package:wms_app/features/expedition/presentation/screens/list_expedition_screen.dart';
import 'package:wms_app/features/expedition/presentation/screens/scan_product_screen.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/detail_screen.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/index.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/scan_product_scree.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/validate_screen.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/view_lote_widget.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/lote_producto.dart';
import 'package:wms_app/features/print_labels/presentation/index.dart';
import 'package:wms_app/features/print_labels/presentation/screens/list_products_screen.dart';
import 'package:wms_app/features/print_labels/presentation/screens/list_locations_screen.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/screens/list_recepcion_multiusuario_screen.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/screens/recepcion_multiusuario_detail_screen.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/screens/location_dest_screen.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/screens/new_lote_screen.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/screens/scan_product_screen.dart';
import 'package:wms_app/src/presentation/views/conteo/models/conteo_response_model.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/conteo_screen.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/list_conteo_screen.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/new_product_screen.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/scan_product_screen.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/lote/new_lote_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/location/location_search_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/lote/search_lote_widget.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/widgets/new_product/product/product_search_widget.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/index.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/locations_dest_screen.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/terceros_screen.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/propietario_screen.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/almacenes_screen.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/screens/create-transfer/create_mass_trasnfer_screen.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/screens/create-transfer/widgets/locationDest/location_search_widget.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/screens/list_locations_screen.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/screens/list_products_screen.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/screens/locations_info_screen.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/screens/paquete_info_screen.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/screens/product_info_screen.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/transfer/screens/transfer_info_screen.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/transfer/widget/locations_dest_widget.dart';
import 'package:wms_app/features/inventario/domain/entities/producto_inventario.dart';
import 'package:wms_app/src/presentation/providers/db/models/response_products_model.dart'
    show Product;
import 'package:wms_app/features/inventario/presentation/widgets/location_search_widget.dart';
import 'package:wms_app/features/inventario/presentation/widgets/new_lote_widget.dart';
import 'package:wms_app/features/inventario/presentation/widgets/product_search_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_batch_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/models/recepcion_response_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/index_list.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/screens/recepcion_batch_screen.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/screens/scan_product_screen.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/widgets/locations_dest/locations_dest_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/batchs/widgets/new_lote_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/list_devoluctions_screen.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/list_ordernes_compra_screen.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/scan_product_screen.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/locations_dest/locations_dest_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/new_lote_widget.dart';
import 'package:wms_app/src/presentation/views/pages.dart';
import 'package:wms_app/features/enterprise/presentation/pages/enterprise_page.dart';
import 'package:wms_app/features/login/presentation/screens/update_required_screen.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/screens/detail_create_tranfer_screen.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/screens/scan_product_create_transfer_screen.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/screens/widgets/location/location_search_widget.dart';
import 'package:wms_app/src/presentation/views/transferencias/models/response_transferencias.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/screens/widgets/lote/search_lote_widget.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/screens/widgets/product/product_search_widget.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/entrega-productos/list_entrada_productos_screen.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/screens/list_transferencias_screen.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/screens/scan_product_transfer_screen.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/screens/transferencia_screen.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/screens/widgets/location_dest/locations_dest_widget.dart';
import 'package:wms_app/features/user/presentation/pages/user_page.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/packing_response_model.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/packing.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/packing_detail.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/packing_list.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/screens/index_list_screen.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/screens/packing_consolidade_detail_screen.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/screens/packing_consolidate_list_screen.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/screens/scan_product_screen.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/index.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/locations_dest_screen.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/packing_detail.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/sacn_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/batch_detail.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/batch_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/screens/history_pick/detail_pick_donde_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/screens/history_pick/index_list_pick__done_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/screens/index_list_pick_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/screens/pick_detail_pick_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/screens/scan_product_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/history/screens/history_detail_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/history/screens/list_batchs_history_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/picking_componentes/batch/index_list_picking_componentes_batchs_screen.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/picking_componentes/index_list_picking_componentes_screen.dart';

class AppRoutes {
  //todas las pantallas de Print Labels
  static const String printLabels = 'print-labels';
  static const String printLabelsProducts = 'print-labels-products';
  static const String printLabelsLocations = 'print-labels-locations';

  //todas las pantallas de Mapa estático de rutas
  static const String enterprice = 'enterprice';
  static const String auth = 'auth';
  static const String checkout = 'checkout';
  static const String updateRequired = 'update-required';

  //todas las pantallas de WMS Picking
  static const String wmsPicking = 'wms-picking';
  static const String batch = 'batch';
  static const String batchDetail = 'batch-detail';
  static const String historyLits = 'history-list';
  static const String historyDetail = 'history-detail';

  //todas las pantallas de picking cluster
  static const String pickingCluster = 'picking-cluster';
  static const String scanProductCluster = 'scan-product-cluster';
  static const String detailCluster = 'detail-cluster';
  static const String validateCluster = 'validate-cluster';
  static const String selectLoteCluster = 'select-lote-cluster';

  //todas las pantallas de pick
  static const String pick = 'pick';
  static const String pickDone = 'pick-done';
  static const String scanProductPick = "scan-product-pick";
  static const String pickDetail = 'pick-detail';
  static const String detailPickDone = 'detail-pick-done';

  //todas las pantallas de picking componentes
  static const String pickingComponentes = 'picking-componentes';
  //por batch
  static const String pickingComponentesBatch = 'picking-componentes-batch';

  //todas las pantallas de WMS Packing
  static const String wmsPacking = 'wms-packing';
  static const String packingList = 'packing-list';
  static const String packing = 'Packing';
  static const String packingDetail = 'packing-detail';

  //todas las pantallas de packing consolidade
  static const String listPackingConsolidade = 'list-packing-consolidade';
  static const String packingConsolidateList =
      'pedido-packing-consolidate-list';
  static const String packingConsolidateDetail = 'packing-consolidate-detail';
  static const String scanProductConsolidate = 'scan-product-consolidate';

  //todas las pantallas de packing por pedido
  static const String listPacking = 'list-packing';
  static const String detailPackingPedido = 'detail-packing-pedido';
  static const String scanPack = 'scan-pack';
  static const String locationsDestPacking = 'locations-dest-packing';

  //todas las pantallas de inventario
  static const String inventario = 'inventario';
  static const String searchLocation = 'search-location';
  static const String searchProduct = 'search-product';
  static const String newLoteInventario = 'new-lote-inventario';

  //todas las pantallas de transferencias
  static const String transferencias = 'transferencias';
  static const String transferenciaDetail = 'transferencia-detail';
  static const String transferExterna = 'transfer-externa';
  static const String searchLocationTrans = 'search-location-trans';
  static const String scanProductTransfer = 'scan-product-transfer';
  static const String searchLocationDestTrans = 'seacrh-locationsDest-trans';

  //todas las pantallas de create transfer
  static const String createTransfer = 'create-transfer';
  static const String searchLocationCreateTransfer =
      'search-location-create-transfer';
  static const String searchProductsCreateTransfer =
      'search-product-create-transfer';
  static const String searchLoteCreateTransfer = 'search-lote-create-transfer';
  static const String detailCreateTransfer = 'detail-create-transfer';

  //todas las pantallas de entrada de productos
  static const String entradaProductos = 'list-entrada-productos';

  //todas las pantallas de Global
  static const String home = '/home';
  static const String user = 'user';

  //todas las pantallas de devoluciones individual
  static const String devoluciones = 'list-devoluciones';

  //todas las pantallas de recepcion
  static const String recepcion = 'recepcion';
  static const String listOrdenesCompra = 'list-ordenes-compra';
  static const String scanProductOrder = 'scan-product-order';
  static const String locationDestSearch = 'search-location-recep';
  //todas las pantallas de recepcion batch
  static const String listReceptionBatch = 'list-recepction-batch';
  static const String recepcionBatch = 'recepcion-batch';
  static const String scanProductReceptionBatch =
      'scan-product-reception-batch';
  static const String locationDestReceptionBatchSearch =
      'search-location-recep-batch';
  static const String newLoteRecepBatch = 'new-lote-recep-batch';

  //todas las pantallas de new lote
  static const String newLote = 'new-lote';

  //todas las pantallas de devoluciones
  static const String devolucionesCreate = 'devoluciones-create';
  static const String terceros = 'terceros';
  static const String propietarioDevoluciones = 'propietario-devoluciones';
  static const String almacenesDevoluciones = 'almacenes-devoluciones';
  static const String ubicacionesDevoluciones = 'ubicaciones-devoluciones';

  //todas las pantallas de info rapida
  static const String infoRapida = 'info-rapida';
  static const String productInfo = 'product-info';
  static const String locationInfo = 'location-info';
  static const String paqueteInfo = 'paquete-info';
  static const String transferInfo = 'transfer-info';
  static const String listLocation = 'list-location';
  static const String listProduct = 'list-product';
  static const String searchLocationDestTransInfo =
      'search-locations-dest-trans-info';
  static const String createMassTransfer = 'create-mass-transfer';
  static const String searchLocationCreateMassTransfer =
      'search-location-create-mass-transfer';

  //todas las pantallas de asistente ia
  static const String asistenteIa = 'asistente-ia';

  //todas las pantallas de conteo
  static const String conteo = 'conteo';
  static const String conteoDetail = 'conteo-detail';
  static const String scanProductConteo = 'scan-product-conteo';
  static const String newLoteOrden = 'new-lote-orden';
  static const String newProductConteo = 'new-product-conteo';
  static const String searchLocationConteo = 'search-location-conteo';
  static const String searchProductConteo = 'search-product-conteo';
  static const String searchLoteConteo = 'search-lote-conteo';

  //todas las pantallas de expedición
  static const String listExpedition = 'list-expedition';
  static const String scanProductExpedition = 'scan-product-expedition';
  static const String expeditionDetail = 'expedition-detail';

  //todas las pantallas de recepción multiusuario
  static const String listRecepcionMultiusuario = 'list-recepcion-multiusuario';
  static const String recepcionMultiusuarioDetail =
      'recepcion-multiusuario-detail';
  static const String recepcionMultiusuarioScanProduct =
      'recepcion-multiusuario-scan-product';
  static const String recepcionMultiusuarioNewLote =
      'recepcion-multiusuario-new-lote';
  static const String recepcionMultiusuarioLocationDest =
      'recepcion-multiusuario-location-dest';

  // ─── Helpers de extracción segura de argumentos ───────────────────────────

  /// Extrae de forma segura la lista de argumentos de la ruta actual.
  /// Devuelve null si no hay argumentos o si no son una List<dynamic>.
  static List<dynamic>? _args(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List<dynamic>) return args;
    return null;
  }

  /// Extrae el argumento en [index] con el tipo [T].
  /// Devuelve null si la lista es null, el índice está fuera de rango,
  /// o el valor no es del tipo esperado.
  static T? _arg<T>(List<dynamic>? args, int index) {
    if (args == null || args.length <= index) return null;
    final value = args[index];
    return value is T ? value : null;
  }

  /// Pantalla de fallback cuando los argumentos obligatorios son inválidos.
  /// Navega de vuelta a home en el siguiente frame para evitar quedar en
  /// una pantalla vacía.
  static Widget _invalidArgs(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });
    return const Scaffold(body: SizedBox.shrink());
  }

  // ──────────────────────────────────────────────────────────────────────────

  static Map<String, Widget Function(BuildContext)> get routes {
    return {
      AppRoutes.checkout: (context) => const CheckAuthPage(),
      AppRoutes.updateRequired: (_) => const UpdateRequiredScreen(),

      AppRoutes.printLabels: (_) => const PrintLabelsScreen(),
      AppRoutes.printLabelsProducts: (_) => const PrintLabelsProductsScreen(),
      AppRoutes.printLabelsLocations: (_) => const PrintLabelsLocationsScreen(),

      //todo expedición
      listExpedition: (_) => const ListExpeditionScreen(),
      scanProductExpedition: (context) {
        final args = _args(context);
        final paquete = _arg<PaqueteExpedicion>(args, 0);
        final itemSuelto = _arg<ItemSueltoExpedicion>(args, 1);
        return ScanProductExpeditionScreen(
          paquete: paquete,
          itemSuelto: itemSuelto,
        );
      },
      expeditionDetail: (context) {
        final args = _args(context);
        final expeditionId = _arg<int>(args, 0) ?? 0;
        return ExpedicionDetailScreen(expeditionId: expeditionId);
      },

      //todo recepción multiusuario
      listRecepcionMultiusuario: (_) => const ListRecepcionMultiusuarioScreen(),
      recepcionMultiusuarioDetail: (context) {
        final args = _args(context);
        final session = _arg<RecepcionSession>(args, 0);
        if (session == null) return _invalidArgs(context);
        return RecepcionMultiusuarioDetailScreen(session: session);
      },
      recepcionMultiusuarioScanProduct: (context) {
        final args = _args(context);
        final session = _arg<RecepcionSession>(args, 0);
        final claim = _arg<RecepcionClaim>(args, 1);
        if (session == null || claim == null) return _invalidArgs(context);
        return RecepcionMultiusuarioScanProductScreen(
          session: session,
          claim: claim,
        );
      },
      recepcionMultiusuarioNewLote: (context) {
        final args = _args(context);
        final session = _arg<RecepcionSession>(args, 0);
        final claim = _arg<RecepcionClaim>(args, 1);
        if (session == null || claim == null) return _invalidArgs(context);
        return RecepcionMultiusuarioNewLoteScreen(
          session: session,
          claim: claim,
        );
      },
      recepcionMultiusuarioLocationDest: (_) =>
          const RecepcionMultiusuarioLocationDestScreen(),

      //todo conteo
      conteo: (_) => const ListConteoScreen(),

      conteoDetail: (context) {
        final args = _args(context);
        final initialTabIndex = _arg<int>(args, 0);
        final ordenConteo = _arg<DatumConteo>(args, 1);
        if (initialTabIndex == null || ordenConteo == null)
          return _invalidArgs(context);
        return ConteoScreen(
          initialTabIndex: initialTabIndex,
          ordenConteo: ordenConteo,
        );
      },

      scanProductConteo: (_) => const ScanProductConteoScreen(),

      newLoteOrden: (context) {
        final args = _args(context);
        final currentProduct = _arg<CountedLine>(args, 0);
        return NewLoteOrdenScreen(currentProduct: currentProduct);
      },

      newProductConteo: (_) => const NewProductConteoScreen(),
      searchLocationConteo: (_) => const SearchLocationConteoScreen(),
      searchProductConteo: (_) => const SearchProductConteoScreen(),

      searchLoteConteo: (context) {
        final args = _args(context);
        final currentProduct = _arg<CountedLine>(args, 0);
        return SearchLoteConteoScreen(currentProduct: currentProduct);
      },

      // todo Global
      enterprice: (_) => const EnterprisePage(),
      auth: (_) => const LoginPage(),

      // todo WMS Picking
      wmsPicking: (context) => WMSPickingPage(),
      batch: (_) => const BatchScreen(),
      batchDetail: (_) => const BatchDetailScreen(),
      historyLits: (_) => const HistoryListScreen(),
      historyDetail: (_) => const HistoryDetailScreen(),
      pick: (_) => const IndexListPickScreen(),

      pickDone: (context) {
        final args = _args(context);
        final isFromPick = _arg<bool>(args, 0);
        if (isFromPick == null) return _invalidArgs(context);
        return IndexListPickDoneScreen(isFromPick: isFromPick);
      },

      scanProductPick: (_) => const ScanProductPickScreen(),
      pickDetail: (_) => const PickDetailScreen(),

      detailPickDone: (context) {
        final args = _args(context);
        final isFromPick = _arg<bool>(args, 0);
        if (isFromPick == null) return _invalidArgs(context);
        return DetailPickDoneScreen(isFromPick: isFromPick);
      },

      //todo picking componentes
      pickingComponentes: (_) => IndexListPickComponentsScreen(),
      pickingComponentesBatch: (_) => PickingCompoBatchScreen(),

      //todo picking cluster
      pickingCluster: (_) => const PickingClusterScreen(),
      scanProductCluster: (_) => const ScanProductCluster(),
      detailCluster: (_) => const DetailClusterScreen(),
      validateCluster: (_) => const ValidateScreen(),

      selectLoteCluster: (context) {
        final args = _args(context);
        final lotes = _arg<List<LoteProducto>>(args, 0);
        final suggestedLoteId = _arg<int>(args, 1);
        if (lotes == null) return _invalidArgs(context);
        return ViewLoteScreen(lotes: lotes, suggestedLoteId: suggestedLoteId);
      },

      // todo WMS Packing
      wmsPacking: (_) => const WmsPackingScreen(),

      packingList: (context) {
        final args = _args(context);
        final batchModel = _arg<BatchPackingModel>(args, 0);
        return PakingListScreen(batchModel: batchModel);
      },

      packing: (context) {
        final args = _args(context);
        final packingModel = _arg<PedidoPacking>(args, 0);
        final batchModel = _arg<BatchPackingModel>(args, 1);
        return PackingScreen(
          packingModel: packingModel,
          batchModel: batchModel,
        );
      },

      packingDetail: (context) {
        final args = _args(context);
        final packingModel = _arg<PedidoPacking>(args, 0);
        final batchModel = _arg<BatchPackingModel>(args, 1);
        final initialTabIndex = _arg<int>(args, 2);
        if (initialTabIndex == null) return _invalidArgs(context);
        return PackingDetailScreen(
          packingModel: packingModel,
          batchModel: batchModel,
          initialTabIndex: initialTabIndex,
        );
      },

      //todo packing consolidade
      listPackingConsolidade: (_) => ListPackingConsolidadeScreen(),

      packingConsolidateList: (context) {
        final args = _args(context);
        final batchModel = _arg<BatchPackingModel>(args, 0);
        return PackingConsolidateListScreen(batchModel: batchModel);
      },

      packingConsolidateDetail: (context) {
        final args = _args(context);
        final packingModel = _arg<PedidoPacking>(args, 0);
        final batchModel = _arg<BatchPackingModel>(args, 1);
        final initialTabIndex = _arg<int>(args, 2);
        if (initialTabIndex == null) return _invalidArgs(context);
        return PackingConsolidateDetailScreen(
          packingModel: packingModel,
          batchModel: batchModel,
          initialTabIndex: initialTabIndex,
        );
      },

      scanProductConsolidate: (context) {
        final args = _args(context);
        final packingModel = _arg<PedidoPacking>(args, 0);
        final batchModel = _arg<BatchPackingModel>(args, 1);
        return ScanProductPackingConsolidateScreen(
          packingModel: packingModel,
          batchModel: batchModel,
        );
      },

      //todo packing por pedido
      listPacking: (_) => ListPackingScreen(),

      detailPackingPedido: (context) {
        final args = _args(context);
        final initialTabIndex = _arg<int>(args, 0);
        if (initialTabIndex == null) return _invalidArgs(context);
        return PackingPedidoDetailScreen(initialTabIndex: initialTabIndex);
      },

      scanPack: (_) => ScanPackScreen(),

      locationsDestPacking: (context) {
        final args = _args(context);
        final isMoreItems = _arg<bool>(args, 0);
        if (isMoreItems == null) return _invalidArgs(context);
        return LocationDestPackingScreen(isMoreItems: isMoreItems);
      },

      //todo auth
      home: (_) => const HomePage(),
      user: (_) => const UserPage(),

      //todo  inventario
      inventario: (_) => const InventarioScreen(),
      searchLocation: (_) => const SearchLocationScreen(),
      searchProduct: (_) => const SearchProductScreen(),

      newLoteInventario: (context) {
        final args = _args(context);
        final currentProduct = _arg<ProductoInventario>(args, 0);
        return NewLoteInventarioScreen(currentProduct: currentProduct);
      },

      locationDestSearch: (context) {
        final args = _args(context);
        final ordenCompraArg = _arg<ResultEntrada>(args, 0);
        final currentProducArg = _arg<LineasTransferencia>(args, 1);
        return LocationDestRecepScreen(
          ordenCompra: ordenCompraArg,
          currentProduct: currentProducArg,
        );
      },

      // todo Recepcion
      scanProductOrder: (context) {
        final args = _args(context);
        final ordenCompraArg = _arg<ResultEntrada>(args, 0);
        final currentProducArg = _arg<LineasTransferencia>(args, 1);
        return ScanProductOrderScreen(
          ordenCompra: ordenCompraArg,
          currentProduct: currentProducArg,
        );
      },

      scanProductTransfer: (context) {
        final args = _args(context);
        final currentProducArg = _arg<LineasTransferenciaTrans>(args, 0);
        return ScanProductTrasnferScreen(currentProduct: currentProducArg);
      },

      searchLocationDestTrans: (context) {
        final args = _args(context);
        final currentProducArg = _arg<LineasTransferenciaTrans>(args, 0);
        return LocationDestTransScreen(currentProduct: currentProducArg);
      },

      recepcion: (context) {
        final args = _args(context);
        final ordenCompraArg = _arg<ResultEntrada>(args, 0);
        final initialTabIndexArg = _arg<int>(args, 1);
        return RecepcionScreen(
          ordenCompra: ordenCompraArg,
          initialTabIndex: initialTabIndexArg ?? 0,
        );
      },

      listOrdenesCompra: (_) => ListOrdenesCompraScreen(),

      //todo devoluciones individual
      devoluciones: (_) => const ListDevolutionsScreen(),

      //todo recepcion batch
      listReceptionBatch: (_) => const ListRecepctionBatchScreen(),

      recepcionBatch: (context) {
        final args = _args(context);
        final recepcionBatchArg = _arg<ReceptionBatch>(args, 0);
        final initialTabIndexArg = _arg<int>(args, 1);
        return RecepcionBatchScreen(
          recepcionBatch: recepcionBatchArg,
          initialTabIndex: initialTabIndexArg ?? 0,
        );
      },

      scanProductReceptionBatch: (context) {
        final args = _args(context);
        final recepcionBatchArg = _arg<ReceptionBatch>(args, 0);
        final currentProducArg = _arg<LineasRecepcionBatch>(args, 1);
        return ScanProductRceptionBatchScreen(
          ordenCompra: recepcionBatchArg,
          currentProduct: currentProducArg,
        );
      },

      locationDestReceptionBatchSearch: (context) {
        final args = _args(context);
        final recepcionBatchArg = _arg<ReceptionBatch>(args, 0);
        final currentProducArg = _arg<LineasRecepcionBatch>(args, 1);
        return LocationDestRecepBatchScreen(
          ordenCompra: recepcionBatchArg,
          currentProduct: currentProducArg,
        );
      },

      newLoteRecepBatch: (context) {
        final args = _args(context);
        final ordenCompraArg = _arg<ReceptionBatch>(args, 0);
        final currentProducArg = _arg<LineasRecepcionBatch>(args, 1);
        return NewLoteRecepBatchScreen(
          ordenCompra: ordenCompraArg,
          currentProduct: currentProducArg,
        );
      },

      newLote: (context) {
        final args = _args(context);
        final ordenCompraArg = _arg<ResultEntrada>(args, 0);
        final currentProducArg = _arg<LineasTransferencia>(args, 1);
        return NewLoteScreen(
          ordenCompra: ordenCompraArg,
          currentProduct: currentProducArg,
        );
      },

      //todo info rapida
      infoRapida: (_) => const InfoRapidaScreen(),
      productInfo: (_) => ProductInfoScreen(),

      locationInfo: (context) {
        final args = _args(context);
        final info = _arg<InfoRapidaResult>(args, 0);
        return LocationInfoScreen(infoRapidaResult: info);
      },

      paqueteInfo: (context) {
        final args = _args(context);
        final info = _arg<InfoRapidaResult>(args, 0);
        return PaqueteInfoScreen(infoRapidaResult: info);
      },

      createMassTransfer: (_) => const CreateMassTrasferScreen(),

      searchLocationCreateMassTransfer: (context) {
        final args = _args(context);
        final isLocationDest = _arg<bool>(args, 0) ?? false;
        return SearchLocationCreateMassTransfercreen(
          isLocationDest: isLocationDest,
        );
      },

      transferInfo: (context) {
        final args = _args(context);
        final info = _arg<InfoResult>(args, 0);
        final ubi = _arg<Ubicacion>(args, 1);
        return TransferInfoScreen(infoRapidaResult: info, ubicacion: ubi);
      },

      createTransfer: (_) => const CreateTransferScreen(),

      searchLocationCreateTransfer: (context) {
        final args = _args(context);
        final isLocationDest = _arg<bool>(args, 0) ?? false;
        return SearchLocationCreateTransfercreen(
          isLocationDest: isLocationDest,
        );
      },

      searchLoteCreateTransfer: (context) {
        final args = _args(context);
        final currentProduct = _arg<Product>(args, 0);
        return SearchLoteCreateTransferScreen(currentProduct: currentProduct);
      },

      detailCreateTransfer: (_) => DetailCreateTransferScreen(),
      searchProductsCreateTransfer: (_) => SearchProductCreateTransferScreen(),
      listLocation: (_) => ListLocationsScreen(),
      listProduct: (_) => ListProductsScreen(),

      searchLocationDestTransInfo: (context) {
        final args = _args(context);
        final info = _arg<InfoResult>(args, 0);
        final ubi = _arg<Ubicacion>(args, 1);
        return LocationDestTransfInfoScreen(
          infoRapidaResult: info,
          ubicacion: ubi,
        );
      },

      //todo entrada de productos
      entradaProductos: (_) => ListEntradaProductsScreen(),

      //todo transferencias
      transferencias: (_) => ListTransferenciasScreen(),

      transferenciaDetail: (context) {
        final args = _args(context);
        final transferencia = _arg<ResultTransFerencias>(args, 0);
        final initialTabIndexArg = _arg<int>(args, 1);
        return TransferenciaScreen(
          transferencia: transferencia,
          initialTabIndex: initialTabIndexArg ?? 0,
        );
      },

      //todo devoluciones
      devolucionesCreate: (_) => DevolucionesScreen(),
      terceros: (_) => const Terceroscreen(),
      propietarioDevoluciones: (_) => const PropietarioScreen(),
      almacenesDevoluciones: (_) => const AlmacenesDevolucionesScreen(),
      ubicacionesDevoluciones: (_) => LocationDestDevolucionesScreen(),
    };
  }
}
