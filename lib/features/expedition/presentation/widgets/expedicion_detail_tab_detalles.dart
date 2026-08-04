import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/presentation/bloc/confirm/expedicion_confirm_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/list/expedition_list_bloc.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_confirmar_pedido_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_vencidos_expedicion_widget.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';

/// Tab "Detalles" de expedition_screen.dart: mismo resumen que
/// ExpedicionCardWidget, más el botón "Confirmar pedido" (mismo par de
/// endpoints — complete_transfer / complete_transfer/expire / update_time_transfer
/// — y misma lógica de reintento por vencidos que Tab1PedidoScreen de
/// packing). Si quedan paquetes o productos sueltos pendientes en "Por
/// hacer", el diálogo de confirmación ofrece crear backorder con lo
/// pendiente (mismo patrón que DialogBackorderPack de packing) en vez de
/// bloquear el cierre.
class ExpedicionDetailTabDetalles extends StatefulWidget {
  final ExpedicionDetail detail;

  const ExpedicionDetailTabDetalles({super.key, required this.detail});

  @override
  State<ExpedicionDetailTabDetalles> createState() =>
      _ExpedicionDetailTabDetallesState();
}

class _ExpedicionDetailTabDetallesState
    extends State<ExpedicionDetailTabDetalles> with LoadingDialogMixin {
  ExpedicionDetail get detail => widget.detail;

  // El botón "Confirmar pedido" solo se muestra con este permiso en true —
  // null mientras carga cuenta como "no mostrar" (evita el flash del botón
  // antes de confirmar el permiso). El permiso vive en SQLite
  // (tbl_configurations), no en UserBloc — ese bloc solo se carga si el
  // usuario entra manualmente a "información del usuario" en Home, así que
  // leerlo de ahí lo dejaba siempre en null.
  bool? _hideValidateExpedition;

  // Recordado entre el intento inicial y el reintento por vencidos
  // (_handleReintentarVencidos), para no perder la elección del usuario de
  // crear backorder al forzar productos vencidos.
  bool _crearBackorderPendiente = false;

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

    if (detail.paquetesListos.isEmpty && detail.itemsSueltosListos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No hay paquetes en estado listo para confirmar'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // No se puede cerrar la expedición completa si hay validaciones hechas sin
    // conexión que todavía no llegaron al backend: se enviarán solas al volver
    // la red y recién ahí podrá confirmarse.
    if (detail.tienePendientesDeSync) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Hay validaciones sin conexión pendientes de enviar. Se enviarán '
            'automáticamente al recuperar conexión; espera a que se sincronicen '
            'para confirmar.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ));
      return;
    }

    final totalPaquetes = detail.paquetesListos.length;
    final totalItems = detail.itemsSueltosListos.length;
    final hayPendientes = detail.paquetesPendientes.isNotEmpty ||
        detail.itemsSueltosPendientes.isNotEmpty;

    void confirmar(BuildContext dialogContext, bool crearBackorder) {
      Navigator.pop(dialogContext);
      _crearBackorderPendiente = crearBackorder;
      context.read<ExpedicionConfirmBloc>().add(ConfirmarPedidoEvent(
          expeditionId: expeditionId, crearBackorder: crearBackorder));
    }

    showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirmarPedidoWidget(
        message: hayPendientes
            ? '¿Está seguro de confirmar la expedición "${pedido.nombre ?? "sin nombre"}" '
                'con $totalPaquetes paquete(s) y $totalItems producto(s) suelto(s)? '
                'Aún quedan paquetes o productos pendientes en "Por hacer": '
                'puede confirmar creando una backorder con lo pendiente, o '
                'confirmar sin backorder para descartarlo.'
            : '¿Está seguro de confirmar la expedición "${pedido.nombre ?? "sin nombre"}" '
                'con $totalPaquetes paquete(s) y $totalItems producto(s) suelto(s)?',
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () => confirmar(dialogContext, false),
        onAcceptedConBackorder:
            hayPendientes ? () => confirmar(dialogContext, true) : null,
      ),
    );
  }

  void _handleReintentarVencidos(BuildContext context) {
    final expeditionId = detail.pedido.expeditionId;
    if (expeditionId == null) return;
    context.read<ExpedicionConfirmBloc>().add(ConfirmarPedidoEvent(
        expeditionId: expeditionId,
        forzarVencidos: true,
        crearBackorder: _crearBackorderPendiente));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pedido = detail.pedido;
    final mostrarBoton =
        pedido.isTerminated != true && _hideValidateExpedition == true;

    // Mismo estilo label:valor que Tab1PedidoScreen de packing (label en
    // primaryColorApp, valor en negro/rojo, fontSize 12).
    Widget row(String label, String value, {Color? valueColor}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: primaryColorApp)),
              Expanded(
                child: Text(value,
                    style: TextStyle(fontSize: 12, color: valueColor ?? black)),
              ),
            ],
          ),
        );

    Widget rowIcon(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 15, color: primaryColorApp),
              const SizedBox(width: 5),
              Expanded(
                child: Text(text,
                    style: TextStyle(fontSize: 12, color: color ?? black)),
              ),
            ],
          ),
        );

    return BlocListener<ExpedicionConfirmBloc, ExpedicionConfirmState>(
      listener: (context, state) {
        if (state is ExpedicionConfirmLoading) {
          showLoadingDialog('Confirmando expedición...');
        }
        if (state is ExpedicionConfirmSuccess) {
          hideLoadingDialog(); // cierra el diálogo de carga
          // Confirmar (con o sin backorder) cambia el estado en el backend,
          // así que acá no alcanza con releer la caché local: hay que volver
          // a pedir /api/transferencias/out para traer la lista al día.
          context
              .read<ExpedicionListBloc>()
              .add(const FetchExpedicionesEvent());
          Navigator.pushReplacementNamed(context, AppRoutes.listExpedition);
          Get.snackbar(
            '360 Software Informa',
            'Expedición confirmada correctamente',
            backgroundColor: white,
            colorText: primaryColorApp,
            snackPosition: SnackPosition.TOP,
          );
        }
        if (state is ExpedicionConfirmError) {
          hideLoadingDialog();
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con el nombre de la expedición.
            Text(
              pedido.nombre ?? '',
              style: TextStyle(
                  fontSize: 12,
                  color: primaryColorApp,
                  fontWeight: FontWeight.bold),
            ),
            if (pedido.zonaEntrega != null && pedido.zonaEntrega!.isNotEmpty)
              row('Zona de entrega: ', pedido.zonaEntrega!),
            Visibility(
              visible: pedido.manejoPropietario == true,
              child: row('Propietario: ',
                  pedido.propietario ?? 'Sin propietario'),
            ),
            row('Operación: ', pedido.pickingType ?? ''),
            row('Estado: ', pedido.estado ?? 'Sin estado'),
            if (pedido.observacion != null && pedido.observacion!.isNotEmpty)
              row('Observación: ', pedido.observacion!),
            const Divider(color: black, thickness: 1, height: 5),
            rowIcon(
              Icons.calendar_month_sharp,
              pedido.fecha != null
                  ? DateFormat('dd/MM/yyyy').format(pedido.fecha!)
                  : 'Sin fecha',
            ),
            row('Doc. Origen: ', pedido.documentoOrigen ?? ''),
            row(
              'Cliente: ',
              pedido.cliente ?? 'Sin cliente',
              valueColor: (pedido.cliente == null || pedido.cliente!.isEmpty)
                  ? red
                  : black,
            ),
            row('Cantidad de items: ', '${pedido.totalCantidades ?? 0}'),
            row('Cantidad de paquetes: ', '${pedido.numeroPaquetes ?? 0}'),
            if (pedido.productoSueltos != null && pedido.productoSueltos! > 0)
              row('Producto sueltos: ', '${pedido.productoSueltos}'),
            if (pedido.totalPeso != null && pedido.totalPeso! > 0)
              row('Peso total: ', '${pedido.totalPeso}'),
            rowIcon(
              Icons.person_rounded,
              pedido.responsable == null || pedido.responsable!.isEmpty
                  ? 'Sin responsable'
                  : pedido.responsable!,
              color: (pedido.responsable == null || pedido.responsable!.isEmpty)
                  ? red
                  : black,
            ),
            if (pedido.startTimeTransfer != null &&
                pedido.startTimeTransfer!.isNotEmpty)
              rowIcon(Icons.timer, 'Iniciado: ${pedido.startTimeTransfer}'),
            if (pedido.isTerminated == true)
              rowIcon(Icons.check_circle, 'Expedición confirmada',
                  color: green),
            const SizedBox(height: 10),
            if (mostrarBoton)
              Center(
                child: ElevatedButton(
                  onPressed: () => _handleConfirmar(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(size.width * 0.9, 30),
                    backgroundColor: primaryColorApp,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirmar pedido',
                    style: TextStyle(color: white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
