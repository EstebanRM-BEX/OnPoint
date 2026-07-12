import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/presentation/bloc/confirm/expedicion_confirm_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/detail/expedicion_detail_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/list/expedition_list_bloc.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_confirmar_pedido_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_vencidos_expedicion_widget.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

/// Tab "Detalles" de expedition_screen.dart: mismo resumen que
/// ExpedicionCardWidget, más el botón "Confirmar pedido" (mismo par de
/// endpoints — complete_transfer / complete_transfer/expire / update_time_transfer
/// — y misma lógica de reintento por vencidos que Tab1PedidoScreen de
/// packing). A diferencia de packing, acá no existe backorder parcial: el
/// botón se bloquea mientras queden paquetes o productos sueltos en "Por
/// hacer".
class ExpedicionDetailTabDetalles extends StatefulWidget {
  final ExpedicionDetail detail;

  const ExpedicionDetailTabDetalles({super.key, required this.detail});

  @override
  State<ExpedicionDetailTabDetalles> createState() =>
      _ExpedicionDetailTabDetallesState();
}

class _ExpedicionDetailTabDetallesState
    extends State<ExpedicionDetailTabDetalles> {
  ExpedicionDetail get detail => widget.detail;

  // El botón "Confirmar pedido" solo se muestra con este permiso en true —
  // null mientras carga cuenta como "no mostrar" (evita el flash del botón
  // antes de confirmar el permiso). El permiso vive en SQLite
  // (tbl_configurations), no en UserBloc — ese bloc solo se carga si el
  // usuario entra manualmente a "información del usuario" en Home, así que
  // leerlo de ahí lo dejaba siempre en null.
  bool? _hideValidateExpedition;

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
      _hideValidateExpedition =
          config?.result?.result?.hideValidateExpedition == true;
    });
  }

  void _handleConfirmar(BuildContext context) {
    final pedido = detail.pedido;
    final expeditionId = pedido.expeditionId;
    if (expeditionId == null) return;

    if (detail.paquetesPendientes.isNotEmpty ||
        detail.itemsSueltosPendientes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'No se puede confirmar la expedición con productos pendientes en "Por hacer"'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (detail.paquetesListos.isEmpty && detail.itemsSueltosListos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No hay productos para confirmar'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final totalPaquetes = detail.paquetesListos.length;
    final totalItems = detail.itemsSueltosListos.length;

    showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirmarPedidoWidget(
        message:
            '¿Está seguro de confirmar la expedición "${pedido.nombre ?? "sin nombre"}" '
            'con $totalPaquetes paquete(s) y $totalItems producto(s) suelto(s)?',
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context
              .read<ExpedicionConfirmBloc>()
              .add(ConfirmarPedidoEvent(expeditionId: expeditionId));
        },
      ),
    );
  }

  void _handleReintentarVencidos(BuildContext context) {
    final expeditionId = detail.pedido.expeditionId;
    if (expeditionId == null) return;
    context.read<ExpedicionConfirmBloc>().add(ConfirmarPedidoEvent(
        expeditionId: expeditionId, forzarVencidos: true));
  }

  @override
  Widget build(BuildContext context) {
    final pedido = detail.pedido;
    final mostrarBoton =
        pedido.isTerminated != true && _hideValidateExpedition == true;

    Widget infoRow(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: primaryColorApp),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: TextStyle(fontSize: 13, color: color ?? black)),
              ),
            ],
          ),
        );

    return BlocListener<ExpedicionConfirmBloc, ExpedicionConfirmState>(
      listener: (context, state) {
        if (state is ExpedicionConfirmLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const DialogLoading(message: 'Confirmando expedición...'),
          );
        }
        if (state is ExpedicionConfirmSuccess) {
          Navigator.pop(context);
          if (pedido.expeditionId != null) {
            context
                .read<ExpedicionDetailBloc>()
                .add(LoadExpedicionDetailEvent(pedido.expeditionId!));
          }
          context
              .read<ExpedicionListBloc>()
              .add(const FetchExpedicionesFromDbEvent());
          Get.snackbar(
            '360 Software Informa',
            'Expedición confirmada correctamente',
            backgroundColor: white,
            colorText: primaryColorApp,
            snackPosition: SnackPosition.TOP,
          );
        }
        if (state is ExpedicionConfirmError) {
          Navigator.pop(context);
          if (state.message.contains('expiry.picking.confirmation')) {
            showDialog(
              context: context,
              builder: (dialogContext) => DialogVencidosExpedicionWidget(
                onDiscard: () => Navigator.pop(dialogContext),
                onContinue: () {
                  Navigator.pop(dialogContext);
                  _handleReintentarVencidos(context);
                },
              ),
            );
          } else {
            Get.snackbar(
              'Error',
              state.message,
              backgroundColor: white,
              colorText: red,
              snackPosition: SnackPosition.TOP,
            );
          }
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pedido.nombre ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColorApp,
                  fontSize: 18),
            ),
            const Divider(),
            if (pedido.zonaEntrega != null && pedido.zonaEntrega!.isNotEmpty)
              infoRow(Icons.location_on_outlined, pedido.zonaEntrega!),
            Visibility(
              visible: pedido.manejoPropietario == true,
              child: infoRow(Icons.business_outlined,
                  'Propietario: ${pedido.propietario ?? "Sin propietario"}'),
            ),
            infoRow(Icons.local_shipping_outlined,
                'Operación: ${pedido.pickingType ?? ""}'),
            infoRow(
                Icons.flag_outlined, 'Estado: ${pedido.estado ?? "Sin estado"}'),
            if (pedido.observacion != null && pedido.observacion!.isNotEmpty)
              infoRow(
                  Icons.notes_outlined, 'Observación: ${pedido.observacion}'),
            infoRow(
              Icons.calendar_today,
              pedido.fecha != null
                  ? DateFormat('dd/MM/yyyy').format(pedido.fecha!)
                  : 'Sin fecha',
            ),
            infoRow(Icons.receipt_long,
                'Doc. Origen: ${pedido.documentoOrigen ?? ""}'),
            infoRow(
              Icons.person,
              pedido.cliente ?? 'Sin cliente',
              color: (pedido.cliente == null || pedido.cliente!.isEmpty)
                  ? red
                  : black,
            ),
            infoRow(Icons.add_box_outlined,
                'Cantidad de items: ${pedido.totalCantidades ?? 0}'),
            infoRow(Icons.inventory_2_outlined,
                'Cantidad de paquetes: ${pedido.numeroPaquetes ?? 0}'),
            if (pedido.productoSueltos != null && pedido.productoSueltos! > 0)
              infoRow(Icons.widgets_outlined,
                  'Producto sueltos: ${pedido.productoSueltos}'),
            if (pedido.totalPeso != null && pedido.totalPeso! > 0)
              infoRow(Icons.scale_outlined, 'Peso total: ${pedido.totalPeso}'),
            infoRow(
              Icons.badge_outlined,
              pedido.responsable == null || pedido.responsable!.isEmpty
                  ? 'Sin responsable'
                  : pedido.responsable!,
              color: (pedido.responsable == null || pedido.responsable!.isEmpty)
                  ? red
                  : black,
            ),
            if (pedido.startTimeTransfer != null &&
                pedido.startTimeTransfer!.isNotEmpty)
              infoRow(Icons.timer_outlined,
                  'Iniciado: ${pedido.startTimeTransfer}'),
            if (pedido.isTerminated == true)
              infoRow(Icons.check_circle, 'Expedición confirmada',
                  color: green),
            if (mostrarBoton) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _handleConfirmar(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Confirmar pedido',
                  style: TextStyle(color: white, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
