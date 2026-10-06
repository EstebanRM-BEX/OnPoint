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
import 'package:wms_app/features/expedition/presentation/widgets/dialog_observacion_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_vencidos_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_detalle_datos_card_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_detalle_resumen_card_widget.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/injection_container.dart';
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
    final config = await getIt<ConfiguracionCacheService>()
        .getConfiguration(userId);
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

  void _mostrarDialogoObservacion(BuildContext context, String observacion) {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogObservacionExpedicionWidget(
        observacion: observacion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = detail.pedido;
    final mostrarBoton =
        pedido.isTerminated != true && _hideValidateExpedition == true;

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
          // El ListBloc llega como argumento de ruta y puede estar ya cerrado
          // (la lista que lo creó se desmontó): add() lanzaba "Cannot add new
          // events after calling close" (fatal en Crashlytics). La lista nueva
          // de pushReplacementNamed crea su propio bloc.
          final listBloc = context.read<ExpedicionListBloc>();
          if (!listBloc.isClosed) {
            listBloc.add(const FetchExpedicionesEvent());
          }
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
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  ExpedicionDetalleResumenCardWidget(
                    nombre: pedido.nombre ?? '',
                    estado: pedido.estado,
                    operacion: pedido.pickingType,
                    zonaEntrega: pedido.zonaEntrega,
                    observacion: pedido.observacion,
                    onVerObservacion: () => _mostrarDialogoObservacion(
                        context, pedido.observacion ?? ''),
                  ),
                  const SizedBox(height: 12),
                  ExpedicionDetalleDatosCardWidget(
                    items: '${pedido.totalCantidades ?? 0}',
                    paquetes: '${pedido.numeroPaquetes ?? 0}',
                    peso: '${pedido.totalPeso ?? 0}',
                    datos: [
                      if (pedido.manejoPropietario == true)
                        ExpedicionDetalleDato(
                          icon: Icons.business_outlined,
                          label: 'Propietario',
                          value: pedido.propietario ?? 'Sin propietario',
                          valueColor:
                              pedido.propietario == null ? red : null,
                        ),
                      ExpedicionDetalleDato(
                        icon: Icons.calendar_month_outlined,
                        label: 'Fecha',
                        mono: true,
                        value: pedido.fecha != null
                            ? DateFormat('dd/MM/yyyy').format(pedido.fecha!)
                            : 'Sin fecha',
                      ),
                      ExpedicionDetalleDato(
                        icon: Icons.description_outlined,
                        label: 'Doc. Origen',
                        chip: true,
                        value: pedido.documentoOrigen ?? '',
                      ),
                      ExpedicionDetalleDato(
                        icon: Icons.person_outline,
                        label: 'Cliente',
                        value: pedido.cliente ?? 'Sin cliente',
                        valueColor:
                            (pedido.cliente == null || pedido.cliente!.isEmpty)
                                ? red
                                : const Color(0xFF1E293B),
                      ),
                      if (pedido.productoSueltos != null &&
                          pedido.productoSueltos! > 0)
                        ExpedicionDetalleDato(
                          icon: Icons.category_outlined,
                          label: 'Producto sueltos',
                          value: '${pedido.productoSueltos}',
                        ),
                      ExpedicionDetalleDato(
                        icon: Icons.account_circle_outlined,
                        label: 'Operario',
                        avatar: true,
                        value: pedido.responsable == null ||
                                pedido.responsable!.isEmpty
                            ? 'Sin responsable'
                            : pedido.responsable!,
                        valueColor: (pedido.responsable == null ||
                                pedido.responsable!.isEmpty)
                            ? red
                            : null,
                      ),
                      if (pedido.startTimeTransfer != null &&
                          pedido.startTimeTransfer!.isNotEmpty)
                        ExpedicionDetalleDato(
                          icon: Icons.schedule,
                          label: 'Iniciado',
                          value: pedido.startTimeTransfer!,
                        ),
                      if (pedido.isTerminated == true)
                        const ExpedicionDetalleDato(
                          icon: Icons.check_circle,
                          label: 'Estado',
                          value: 'Expedición confirmada',
                          valueColor: green,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (mostrarBoton)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleConfirmar(context),
                    icon: const Icon(Icons.check, color: white, size: 20),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    label: const Text(
                      'Confirmar pedido',
                      style: TextStyle(
                          color: white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
