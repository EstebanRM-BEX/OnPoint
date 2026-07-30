import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/features/expedition/presentation/bloc/scan/expedicion_scan_bloc.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_validar_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_scan_item_suelto_card_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_scan_item_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_scan_paquete_card_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

/// Screen de detalle de un paquete (items_pack_pendientes) o de un producto
/// suelto (items_pendientes), con la acción "Validar expedición": llama al
/// backend y, si responde ok, marca is_validate=true en
/// SQLite. Al validar con éxito hace pop(true) para que quien navegó hasta
/// acá (expedicion_detail_tab_por_hacer.dart) sepa que debe refrescar.
///
/// El botón "Validar expedición" solo es funcional si el permiso
/// `hide_validate_item_expedition` viene en true/1 — si no, queda
/// deshabilitado y arriba se muestra un texto explicando que hay que
/// escanear el código del paquete/producto. El escáner (siempre activo en
/// esta pantalla, sin importar el permiso) valida contra el
/// packing_barcode del paquete o el barcode del producto suelto y, si
/// coincide, dispara exactamente el mismo flujo que tocar el botón.
class ScanProductExpeditionScreen extends StatefulWidget {
  final PaqueteExpedicion? paquete;
  final ItemSueltoExpedicion? itemSuelto;

  const ScanProductExpeditionScreen({super.key, this.paquete, this.itemSuelto});

  @override
  State<ScanProductExpeditionScreen> createState() =>
      _ScanProductExpeditionScreenState();
}

class _ScanProductExpeditionScreenState
    extends State<ScanProductExpeditionScreen> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  final FocusNode _scanFocusNode = FocusNode();
  final TextEditingController _scanController = TextEditingController();

  // null mientras carga: el permiso vive en SQLite (tbl_configurations), no
  // en UserBloc — ese bloc solo se carga si el usuario entra manualmente a
  // "información del usuario" en Home, así que leerlo de ahí lo dejaba
  // siempre en null (botón nunca funcional aunque el permiso fuera true).
  bool? _puedeValidarConBoton;

  @override
  void initState() {
    super.initState();
    _cargarPermiso();
  }

  Future<void> _cargarPermiso() async {
    final userId = await PrefUtils.getUserId();
    final config =
        await DataBaseSqlite().configurationsRepository.getConfiguration(userId);
    if (!mounted) return;
    setState(() {
      _puedeValidarConBoton =
          config?.result?.result?.hideValidateItemExpedition == true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No robar foco si hay un dialog encima (loading/confirmación).
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    FocusScope.of(context).requestFocus(_scanFocusNode);
  }

  @override
  void dispose() {
    _scanFocusNode.unfocus();
    _scanController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }

  void _handleValidar(BuildContext context) {
    final paquete = widget.paquete;
    final itemSuelto = widget.itemSuelto;
    final message = paquete != null
        ? '¿Está seguro de validar el paquete "${paquete.packageName ?? "sin nombre"}" con sus ${paquete.items.length} producto(s)?'
        : '¿Está seguro de validar el producto "${itemSuelto?.productName ?? "sin nombre"}" con cantidad ${itemSuelto?.quantity ?? 0} ${itemSuelto?.uom ?? ""}?';

    showDialog(
      context: context,
      builder: (dialogContext) => DialogValidarExpedicionWidget(
        message: message,
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context.read<ExpedicionScanBloc>().add(
                ValidarExpedicionScanEvent(
                    paquete: paquete, itemSuelto: itemSuelto),
              );
        },
      ),
    );
  }

  void _handleScan(String value, BuildContext context) {
    final scan = value.trim().toLowerCase();
    _scanController.clear();
    if (scan.isEmpty) return;

    final paquete = widget.paquete;
    final itemSuelto = widget.itemSuelto;

    final coincide = paquete != null
        ? paquete.packingBarcode?.toLowerCase() == scan
        : itemSuelto?.barcode?.toLowerCase() == scan;

    if (coincide) {
      _handleValidar(context);
    } else {
      _showScanError();
    }
    Future.microtask(() => _scanFocusNode.requestFocus());
  }

  void _showScanError() {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El código escaneado no coincide')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paquete = widget.paquete;
    final itemSuelto = widget.itemSuelto;
    final puedeValidarConBoton = _puedeValidarConBoton == true;

    return BlocListener<ExpedicionScanBloc, ExpedicionScanState>(
      listener: (context, state) {
        if (state is ExpedicionScanValidating) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const DialogLoading(message: 'Validando expedición...'),
          );
        }
        if (state is ExpedicionScanValidated) {
          Navigator.pop(context); // cierra el diálogo de carga
          Navigator.pop(context, true); // cierra la screen
        }
        if (state is ExpedicionScanError) {
          Navigator.pop(context); // cierra el diálogo de carga
          Get.snackbar(
            'Error',
            state.message,
            backgroundColor: white,
            colorText: red,
            snackPosition: SnackPosition.TOP,
          );
        }
      },
      child: Scaffold(
        backgroundColor: primaryColorApp,
        appBar: AppBar(
          backgroundColor: primaryColorApp,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: const Text('EXPEDICIÓN',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
          ),
        ),
        body: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                BarcodeScannerField(
                  controller: _scanController,
                  focusNode: _scanFocusNode,
                  onBarcodeScanned: (value, context) =>
                      _handleScan(value, context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (paquete != null) ...[
                        ExpedicionScanPaqueteCardWidget(paquete: paquete),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Text(
                            'Productos',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        ...paquete.items
                            .map((i) => ExpedicionScanItemWidget(item: i)),
                      ] else if (itemSuelto != null)
                        ExpedicionScanItemSueltoCardWidget(item: itemSuelto),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      if (!puedeValidarConBoton)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            paquete != null
                                ? 'Para validar debe escanear el código del paquete'
                                : 'Para validar debe escanear el código del producto',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: puedeValidarConBoton
                            ? () => _handleValidar(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColorApp,
                          disabledBackgroundColor: grey,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'VALIDAR EXPEDICIÓN',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
