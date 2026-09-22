// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/widgets/auth/auth_brand_gradient.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/info_rapida_model.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/location_detail_card.dart';
import 'package:wms_app/src/presentation/views/info_rapida/modules/quick%20info/widgets/mass_transfer_product_card.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class LocationInfoScreen extends StatefulWidget {
  final InfoRapidaResult? infoRapidaResult;

  const LocationInfoScreen({super.key, this.infoRapidaResult});

  @override
  State<LocationInfoScreen> createState() => _LocationInfoScreenState();
}

class _LocationInfoScreenState extends State<LocationInfoScreen> {
  String? _selectedPropietario;

  List<String> _getPropietarios(InfoRapidaBloc bloc) {
    return (bloc.productosUbicacion ?? [])
        .where(
          (p) =>
              (p.manejoPropietario == true || p.manejoPropietario == 1) &&
              p.propietario != null &&
              p.propietario!.isNotEmpty,
        )
        .map((p) => p.propietario!)
        .toSet()
        .toList()
      ..sort();
  }

  void _showPropietarioFilter(BuildContext context, InfoRapidaBloc bloc) {
    final propietarios = _getPropietarios(bloc);

    if (propietarios.isEmpty) {
      Get.snackbar(
        'Sin propietarios',
        'No hay productos con propietario para filtrar',
        backgroundColor: white,
        colorText: primaryColorApp,
        icon: const Icon(Icons.info_outline, color: primaryColorApp),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: primaryColorApp),
                  SizedBox(width: 8),
                  Text(
                    'Filtrar por propietario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColorApp,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                _selectedPropietario == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: primaryColorApp,
              ),
              title: const Text('Todos los propietarios'),
              onTap: () {
                setState(() => _selectedPropietario = null);
                Navigator.pop(context);
              },
            ),
            ...propietarios.map(
              (p) => ListTile(
                leading: Icon(
                  _selectedPropietario == p
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: primaryColorApp,
                ),
                title: Text(p),
                onTap: () {
                  setState(() => _selectedPropietario = p);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocConsumer<InfoRapidaBloc, InfoRapidaState>(
      listener: (context, state) {
        if (state is MassTransferPropietarioMismatchState) {
          Get.snackbar(
            '360 Software Informa',
            state.message,
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.block, color: Colors.red),
            duration: const Duration(seconds: 4),
          );
        } else if (state is InfoRapidaLoading) {
          showDialog(
            context: context,
            builder: (context) {
              return const DialogLoading(message: "Buscando informacion...");
            },
          );
        } else if (state is InfoRapidaLoaded) {
          Navigator.pop(context);
          if (state.infoRapidaResult.type == 'product') {
            Navigator.pushReplacementNamed(
              context,
              'product-info',
              arguments: [context.read<InfoRapidaBloc>()],
            );
          }
        } else if (state is InfoRapidaError) {
          Navigator.pop(context);
          Get.snackbar(
            '360 Software Informa',
            'No se encontró información.',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: Icon(Icons.error, color: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<InfoRapidaBloc>();
        final ubicacion = bloc.infoRapidaResult.result;
        final barcodeController = TextEditingController(
          text: ubicacion?.codigoBarras ?? '',
        );
        final nameController = TextEditingController(
          text: ubicacion?.nombre ?? '',
        );

        void submitUpdate() {
          if (nameController.text.isEmpty || barcodeController.text.isEmpty) {
            Get.snackbar(
              '360 Software Informa',
              'Por favor, complete todos los campos',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: const Icon(Icons.check_circle, color: Colors.red),
            );
            return;
          }

          bloc.add(
            EditLocationEvent(
              ubicacion?.id ?? 0,
              nameController.text,
              barcodeController.text,
            ),
          );
        }

        final massTransferActive = bloc.isMassTransferActive;
        final lista = _selectedPropietario == null
            ? (bloc.productosUbicacion ?? [])
            : (bloc.productosUbicacion ?? [])
                  .where((p) => p.propietario == _selectedPropietario)
                  .toList();
        final disponibles = (bloc.productosUbicacion ?? [])
            .where((p) => p.packing != true && (p.cantidadMano ?? 0) > 0)
            .toList();
        final todosSeleccionados =
            disponibles.isNotEmpty &&
            disponibles.every(
              (p) => bloc.productosFiltersMassTransfer.any((s) => s.id == p.id),
            );

        return WillPopScope(
          onWillPop: () async => false,
          child: Scaffold(
            // Mismo color que el cuerpo: evita la franja plana detrás del
            // status bar separada del header curvo.
            backgroundColor: Colors.grey.shade50,
            body: SafeArea(
              top: false,
              child: Container(
                width: size.width,
                height: size.height,
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    _LocationInfoHeader(
                      isEdit: bloc.isEdit,
                      massTransferActive: massTransferActive,
                      onBack: () {
                        bloc.searchControllerProducts.clear();
                        bloc.add(IsEditEvent(false));
                        bloc.add(ResetProductsFiltersMassTransferEvent());
                        bloc.add(GetListLocationsEvent());
                        Navigator.pushReplacementNamed(
                          context,
                          'info-rapida',
                          arguments: [bloc],
                        );
                      },
                      onEdit: () {
                        if (bloc
                                .configurations
                                .result
                                ?.result
                                ?.updateLocationInventory ==
                            true) {
                          bloc.add(IsEditEvent(!bloc.isEdit));
                        } else {
                          Get.snackbar(
                            '360 Software Informa',
                            'No tiene permiso para editar la ubicación',
                            backgroundColor: white,
                            colorText: primaryColorApp,
                            icon: const Icon(Icons.error, color: Colors.red),
                          );
                        }
                      },
                      onToggleMassTransfer: () {
                        bloc.add(
                          ActivateMassTransferEvent(!massTransferActive),
                        );
                      },
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                        children: [
                          if (ubicacion != null)
                            LocationDetailCard(
                              ubicacion: ubicacion,
                              isEditMode: bloc.isEdit,
                              nameController: nameController,
                              barcodeController: barcodeController,
                              onSubmitUpdate: submitUpdate,
                            ),
                          const SizedBox(height: 14),
                          DynamicSearchBar(
                            controller: bloc.searchControllerProducts,
                            hintText: "Buscar producto o código de barras...",
                            // watchdog: reabre el teclado si el IME del PDA
                            // (Zebra/Urovo/Chainway) lo cierra solo.
                            persistentKeyboard: true,
                            onSearchChanged: (value) {
                              bloc.add(SearchProductLocationEvent(value));
                            },
                            onSearchCleared: () {
                              bloc.searchControllerProducts.clear();
                              bloc.add(SearchProductLocationEvent(''));
                            },
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                "Productos",
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColorApp.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${lista.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColorApp,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (massTransferActive)
                                _PillButton(
                                  icon: todosSeleccionados
                                      ? Icons.deselect
                                      : Icons.select_all,
                                  label: todosSeleccionados
                                      ? "Deselec. todos"
                                      : "Selec. todos",
                                  onTap: () => bloc.add(
                                    SelectAllAvailableProductsEvent(),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              _PillButton(
                                icon: bloc.isAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                label: "Ordenar",
                                onTap: () {
                                  bloc.add(
                                    SortProductsEvent(!bloc.isAscending),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () =>
                                    _showPropietarioFilter(context, bloc),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.person_search_outlined,
                                    color: _selectedPropietario != null
                                        ? Colors.amber.shade800
                                        : primaryColorApp,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(lista.length, (index) {
                            final producto = lista[index];
                            final isSelected = bloc.productosFiltersMassTransfer
                                .any((p) => p.id == producto.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: MassTransferProductCard(
                                producto: producto,
                                massTransferActive: massTransferActive,
                                isSelected: isSelected,
                                onToggleSelected: (selected) {
                                  bloc.add(
                                    ToggleProductMassTransferEvent(
                                      producto,
                                      selected,
                                    ),
                                  );
                                },
                                onOpenDetail: () => getInfoProduct(
                                  producto.id?.toString() ?? '',
                                  context,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: massTransferActive
                ? _MassTransferBar(
                    count: bloc.productosFiltersMassTransfer.length,
                    onTap: () {
                      if (bloc.productosFiltersMassTransfer.isEmpty) {
                        Get.snackbar(
                          '360 Software Informa',
                          'Debe seleccionar al menos un producto para realizar la transferencia masiva',
                          backgroundColor: white,
                          colorText: primaryColorApp,
                          icon: const Icon(Icons.error, color: Colors.red),
                        );
                        return;
                      }
                      Navigator.pushReplacementNamed(
                        context,
                        'create-mass-transfer',
                        arguments: [bloc],
                      );
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  void getInfoProduct(String id, BuildContext context) {
    context.read<InfoRapidaBloc>().add(
      GetInfoRapida(id.toUpperCase(), true, true, false),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColorApp.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColorApp.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primaryColorApp),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColorApp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MassTransferBar extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MassTransferBar({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              foregroundColor: white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.compare_arrows_rounded, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Crear transferencia masiva',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
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

class _LocationInfoHeader extends StatelessWidget {
  final bool isEdit;
  final bool massTransferActive;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onToggleMassTransfer;

  const _LocationInfoHeader({
    required this.isEdit,
    required this.massTransferActive,
    required this.onBack,
    required this.onEdit,
    required this.onToggleMassTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: authBrandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      width: double.infinity,
      // El degradado ya pinta detrás del status bar; este SafeArea solo
      // empuja el contenido interno hacia abajo del notch.
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const WarningWidgetCubit(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: const SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    "INFORMACIÓN RÁPIDA",
                    style: TextStyle(
                      color: white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Material(
                      color: Colors.white.withOpacity(0.15),
                      shape: const CircleBorder(),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(
                          isEdit ? Icons.close : Icons.more_vert,
                          color: white,
                          size: 20,
                        ),
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'mass_transfer') {
                        onToggleMassTransfer();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              isEdit ? Icons.close : Icons.edit,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isEdit ? "Cancelar edición" : "Editar ubicación",
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'mass_transfer',
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz, color: Colors.black54),
                            const SizedBox(width: 10),
                            Text(
                              massTransferActive
                                  ? "Desactivar transferencia masiva"
                                  : "Activar transferencia masiva",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
