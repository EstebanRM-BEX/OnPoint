// app_routes.dart

import 'package:flutter/material.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/detail_screen.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/index.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/scan_product_scree.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/validate_screen.dart';
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
import 'package:wms_app/src/presentation/views/info%20rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/screens/create-transfer/create_mass_trasnfer_screen.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/screens/create-transfer/widgets/locationDest/location_search_widget.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/screens/list_locations_screen.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/screens/list_products_screen.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/screens/locations_info_screen.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/screens/paquete_info_screen.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/screens/product_info_screen.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/transfer/screens/transfer_info_screen.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/transfer/widget/locations_dest_widget.dart';
import 'package:wms_app/src/presentation/views/inventario/models/response_products_model.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/widgets/location/location_search_widget.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/widgets/new_lote_widget.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/widgets/product/product_search_widget.dart';
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
  //todo  Mapa estático de rutas
  static const String enterprice = 'enterprice';
  static const String auth = 'auth';
  static const String checkout = 'checkout';

  //todo  WMS Picking
  static const String wmsPicking = 'wms-picking';
  static const String batch = 'batch';
  static const String batchDetail = 'batch-detail';
  static const String historyLits = 'history-list';
  static const String historyDetail = 'history-detail';

  //todo picking cluster
  static const String pickingCluster = 'picking-cluster';
  static const String scanProductCluster = 'scan-product-cluster';
  static const String detailCluster = 'detail-cluster';
  static const String validateCluster = 'validate-cluster';

  //todo pick
  static const String pick = 'pick';
  static const String pickDone = 'pick-done';
  static const String scanProductPick = "scan-product-pick";
  static const String pickDetail = 'pick-detail';
  static const String detailPickDone = 'detail-pick-done';

  //todo picking componentes
  static const String pickingComponentes = 'picking-componentes';
  //por batch
  static const String pickingComponentesBatch = 'picking-componentes-batch';

  //todo WMS Packing
  static const String wmsPacking = 'wms-packing';
  static const String packingList = 'packing-list';
  static const String packing = 'Packing';
  static const String packingDetail = 'packing-detail';

  //todo packing consolidade
  static const String listPackingConsolidade =
      'list-packing-consolidade'; // lista de batchs de packing consolidados
  static const String packingConsolidateList =
      'pedido-packing-consolidate-list'; // lista de pedidos consolidados por batch packing
  static const String packingConsolidateDetail =
      'packing-consolidate-detail'; // detalles ya del pedido consolidado a separar
  static const String scanProductConsolidate =
      'scan-product-consolidate'; // pantalla de escaneo de productos para consolidar

  //todo packing por pedido
  static const String listPacking = 'list-packing';
  static const String detailPackingPedido = 'detail-packing-pedido';
  static const String scanPack = 'scan-pack';

  //todo inventario
  static const String inventario = 'inventario';
  static const String searchLocation = 'search-location';
  static const String searchProduct = 'search-product';
  static const String newLoteInventario = 'new-lote-inventario';

  //todo transferencias
  static const String transferencias = 'transferencias';
  static const String transferenciaDetail = 'transferencia-detail';
  static const String transferExterna = 'transfer-externa';
  static const String searchLocationTrans = 'search-location-trans';
  static const String scanProductTransfer = 'scan-product-transfer';
  static const String searchLocationDestTrans = 'seacrh-locationsDest-trans';

//todo create transfer
  static const String createTransfer = 'create-transfer';
  static const String searchLocationCreateTransfer =
      'search-location-create-transfer';
  //search-product-create-transfer
  static const String searchProductsCreateTransfer =
      'search-product-create-transfer';

  static const String searchLoteCreateTransfer = 'search-lote-create-transfer';

  static const String detailCreateTransfer = 'detail-create-transfer';

  //todo entrada de productos
  static const String entradaProductos = 'list-entrada-productos';

  //todo Global
  static const String home = '/home';
  static const String user = 'user';

  //todo devoluciones individual
  static const String devoluciones = 'list-devoluciones';

  //todo recepcion
  static const String recepcion = 'recepcion';
  static const String listOrdenesCompra = 'list-ordenes-compra';
  static const String scanProductOrder = 'scan-product-order';
  static const String locationDestSearch = 'search-location-recep';
  //todo recepcion batch
  static const String listReceptionBatch = 'list-recepction-batch';
  static const String recepcionBatch = 'recepcion-batch';
  static const String scanProductReceptionBatch =
      'scan-product-reception-batch';
  static const String locationDestReceptionBatchSearch =
      'search-location-recep-batch';
  static const String newLoteRecepBatch = 'new-lote-recep-batch';

  //todo new lote
  static const String newLote = 'new-lote';

  //todo devoluciones
  static const String devolucionesCreate = 'devoluciones-create';
  static const String terceros = 'terceros';
  static const String ubicacionesDevoluciones = 'ubicaciones-devoluciones';
  //todo info rapida
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

  //todo: conteo
  static const String conteo = 'conteo';
  static const String conteoDetail = 'conteo-detail';
  static const String scanProductConteo = 'scan-product-conteo';
  static const String newLoteOrden = 'new-lote-orden';
  static const String newProductConteo = 'new-product-conteo';
  static const String searchLocationConteo = 'search-location-conteo';
  static const String searchProductConteo = 'search-product-conteo';
  static const String searchLoteConteo = 'search-lote-conteo';

  static Map<String, Widget Function(BuildContext)> get routes {
    return {
      AppRoutes.checkout: (context) => const CheckAuthPage(),
      //todo conteo
      conteo: (_) => const ListConteoScreen(),
      conteoDetail: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final initialTabIndex = arguments[0] as int;
        final ordenConteo = arguments[1] as DatumConteo;
        return ConteoScreen(
          initialTabIndex: initialTabIndex,
          ordenConteo: ordenConteo,
        );
      },
      scanProductConteo: (_) => const ScanProductConteoScreen(),
      newLoteOrden: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final currentProduct = arguments[0] as CountedLine?;
        return NewLoteOrdenScreen(
          currentProduct: currentProduct,
        );
      },

      newProductConteo: (_) => const NewProductConteoScreen(),
      searchLocationConteo: (_) => const SearchLocationConteoScreen(),
      searchProductConteo: (_) => const SearchProductConteoScreen(),
      searchLoteConteo: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final currentProduct = arguments[0] as CountedLine?;
        return SearchLoteConteoScreen(
          currentProduct: currentProduct,
        );
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
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final isFromPick = arguments[0] as bool;
        return IndexListPickDoneScreen(isFromPick: isFromPick);
      },
      scanProductPick: (_) => const ScanProductPickScreen(),
      pickDetail: (_) => const PickDetailScreen(),
      detailPickDone: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final isFromPick = arguments[0] as bool;
        return DetailPickDoneScreen(isFromPick: isFromPick);
      },

      //todo picking componentes
      pickingComponentes: (_) => IndexListPickComponentsScreen(),
      //por batch
      pickingComponentesBatch: (context) {
        return PickingCompoBatchScreen();
      },

      //todo picking cluster
      pickingCluster: (_) => const PickingClusterScreen(),
      scanProductCluster: (_) => const ScanProductCluster(),
      detailCluster: (_) => const DetailClusterScreen(),
      validateCluster: (_) => const ValidateScreen(),

      // todo WMS Packing
      wmsPacking: (_) => const WmsPackingScreen(),

      packingList: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final batchModel = arguments[0] as BatchPackingModel?;
        return PakingListScreen(
          batchModel: batchModel,
        );
      },

      packing: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final packingModel = arguments[0] as PedidoPacking?;
        final batchModel = arguments[1] as BatchPackingModel?;
        return PackingScreen(
          packingModel: packingModel,
          batchModel: batchModel,
        );
      },

      packingDetail: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final packingModel = arguments[0] as PedidoPacking?;
        final batchModel = arguments[1] as BatchPackingModel?;
        final initialTabIndex = arguments[2] as int;

        return PackingDetailScreen(
          packingModel: packingModel,
          batchModel: batchModel,
          initialTabIndex: initialTabIndex,
        );
      },

      //todo packing consolidade
      listPackingConsolidade: (_) => ListPackingConsolidadeScreen(),

      packingConsolidateList: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final batchModel = arguments[0] as BatchPackingModel?;
        return PackingConsolidateListScreen(
          batchModel: batchModel,
        );
      },

      packingConsolidateDetail: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final packingModel = arguments[0] as PedidoPacking?;
        final batchModel = arguments[1] as BatchPackingModel?;
        final initialTabIndex = arguments[2] as int;

        return PackingConsolidateDetailScreen(
          packingModel: packingModel,
          batchModel: batchModel,
          initialTabIndex: initialTabIndex,
        );
      },

      scanProductConsolidate: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final packingModel = arguments[0] as PedidoPacking?;
        final batchModel = arguments[1] as BatchPackingModel?;
        return ScanProductPackingConsolidateScreen(
          packingModel: packingModel,
          batchModel: batchModel,
        );
      },

      //todo packign por pedido
      listPacking: (_) => ListPackingScreen(),

      detailPackingPedido: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final initialTabIndex = arguments[0] as int;
        return PackingPedidoDetailScreen(
          initialTabIndex: initialTabIndex,
        );
      },
      scanPack: (_) => ScanPackScreen(),

      //todo auth
      home: (_) => const HomePage(),
      user: (_) => const UserPage(),

      //todo  inventario
      inventario: (_) => const InventarioScreen(),

      searchLocation: (_) => const SearchLocationScreen(),
      searchProduct: (_) => const SearchProductScreen(),
      newLoteInventario: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final currentProduct = arguments[0] as Product?;
        return NewLoteInventarioScreen(
          currentProduct: currentProduct,
        );
      },

      //BUSCADOR UBICACION DESTINO
      locationDestSearch: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final ordenCompraArg = arguments[0] as ResultEntrada?;
        final currentProducArg = arguments[1] as LineasTransferencia?;
        return LocationDestRecepScreen(
            ordenCompra: ordenCompraArg, currentProduct: currentProducArg);
      },

      // todo Recepcion

      scanProductOrder: (context) {
        final arguments =
            ModalRoute.of(context)?.settings.arguments as List<dynamic>?;

        // Asignación segura con verificación de tipo
        final ResultEntrada? ordenCompraArg =
            (arguments != null && arguments.isNotEmpty)
                ? arguments[0] as ResultEntrada?
                : null;
        final LineasTransferencia? currentProducArg =
            (arguments != null && arguments.length > 1)
                ? arguments[1] as LineasTransferencia?
                : null;

        return ScanProductOrderScreen(
            ordenCompra: ordenCompraArg, currentProduct: currentProducArg);
      },

      scanProductTransfer: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final currentProducArg = arguments[0] as LineasTransferenciaTrans?;
        return ScanProductTrasnferScreen(currentProduct: currentProducArg);
      },

      searchLocationDestTrans: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final currentProducArg = arguments[0] as LineasTransferenciaTrans?;
        return LocationDestTransScreen(currentProduct: currentProducArg);
      },

      recepcion: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final ordenCompraArg = arguments[0] as ResultEntrada?;
        final initialTabIndexArg = arguments[1] as int?;
        return RecepcionScreen(
            ordenCompra: ordenCompraArg,
            initialTabIndex: initialTabIndexArg ?? 0);
      },

      listOrdenesCompra: (_) => ListOrdenesCompraScreen(),

      //todo devoluciones individual
      devoluciones: (_) => const ListDevolutionsScreen(),

      //todo recepcion batch
      listReceptionBatch: (_) => const ListRecepctionBatchScreen(),

      recepcionBatch: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final recepcionBatch = arguments[0] as ReceptionBatch?;
        final initialTabIndexArg = arguments[1] as int?;
        return RecepcionBatchScreen(
            recepcionBatch: recepcionBatch,
            initialTabIndex: initialTabIndexArg ?? 0);
      },

      scanProductReceptionBatch: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final recepcionBatch = arguments[0] as ReceptionBatch?;
        final currentProducArg = arguments[1] as LineasRecepcionBatch?;
        return ScanProductRceptionBatchScreen(
            ordenCompra: recepcionBatch, currentProduct: currentProducArg);
      },

      locationDestReceptionBatchSearch: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final recepcionBatch = arguments[0] as ReceptionBatch?;
        final currentProducArg = arguments[1] as LineasRecepcionBatch?;
        return LocationDestRecepBatchScreen(
            ordenCompra: recepcionBatch, currentProduct: currentProducArg);
      },

      //todo lote por batch
      newLoteRecepBatch: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final ordenCompraArg = arguments[0] as ReceptionBatch?;
        final currentProducArg = arguments[1] as LineasRecepcionBatch?;
        return NewLoteRecepBatchScreen(
            ordenCompra: ordenCompraArg, currentProduct: currentProducArg);
      },

      //todo lote
      newLote: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final ordenCompraArg = arguments[0] as ResultEntrada?;
        final currentProducArg = arguments[1] as LineasTransferencia?;
        return NewLoteScreen(
            ordenCompra: ordenCompraArg, currentProduct: currentProducArg);
      },

      //todo info rapida
      infoRapida: (_) => const InfoRapidaScreen(),

      productInfo: (context) {
        return ProductInfoScreen();
      },

      locationInfo: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final info = arguments[0] as InfoRapidaResult?;
        return LocationInfoScreen(
          infoRapidaResult: info,
        );
      },
      paqueteInfo: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final info = arguments[0] as InfoRapidaResult?;
        return PaqueteInfoScreen(
          infoRapidaResult: info,
        );
      },

      createMassTransfer: (_) => const CreateMassTrasferScreen(),

      searchLocationCreateMassTransfer: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final isLocationDest = arguments[0] as bool?;
        return SearchLocationCreateMassTransfercreen(
          isLocationDest: isLocationDest ?? false,
        );
      },

      //todo transfer info
      transferInfo: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        // Asegurarnos de que la lista tenga al menos dos elementos
        final info = arguments[0] as InfoResult?;
        final ubi = arguments[1] as Ubicacion?;
        return TransferInfoScreen(
          infoRapidaResult: info,
          ubicacion: ubi,
        );
      },

      createTransfer: (_) => const CreateTransferScreen(),
      searchLocationCreateTransfer: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        // Asegurarnos de que la lista tenga al menos dos elementos
        final isLocationDest = arguments[0] as bool?;
        return SearchLocationCreateTransfercreen(
          isLocationDest: isLocationDest ?? false,
        );
      },

      searchLoteCreateTransfer: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final currentProduct = arguments[0] as Product?;
        return SearchLoteCreateTransferScreen(
          currentProduct: currentProduct,
        );
      },

      detailCreateTransfer: (context) {
        return DetailCreateTransferScreen();
      },

      searchProductsCreateTransfer: (_) => SearchProductCreateTransferScreen(),

      listLocation: (_) {
        return ListLocationsScreen();
      },
      listProduct: (_) {
        return ListProductsScreen();
      },

      searchLocationDestTransInfo: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final info = arguments[0] as InfoResult?;
        final ubi = arguments[1] as Ubicacion?;
        return LocationDestTransfInfoScreen(
          infoRapidaResult: info,
          ubicacion: ubi,
        );
      },

      //todo entrada de productos
      entradaProductos: (_) {
        return ListEntradaProductsScreen();
      },

      //todo transferencias
      transferencias: (_) {
        return ListTransferenciasScreen();
      },

      transferenciaDetail: (context) {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as List<dynamic>;
        final transferencia = arguments[0] as ResultTransFerencias?;
        final initialTabIndexArg = arguments[1] as int?;
        return TransferenciaScreen(
          transferencia: transferencia,
          initialTabIndex: initialTabIndexArg ?? 0,
        );
      },

      //todo devoluciones
      devolucionesCreate: (_) => DevolucionesScreen(),
      terceros: (_) => const Terceroscreen(),
      ubicacionesDevoluciones: (_) => LocationDestDevolucionesScreen(),
    };
  }
}
