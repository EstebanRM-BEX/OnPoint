import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/location_dest/recepcion_multiusuario_location_dest_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

/// Réplica de LocationDestRecepScreen (recepción individual) para
/// multiusuario: buscar/seleccionar una ubicación destino, con el mismo
/// filtro por almacén (menú "⋮" del appbar). Las ubicaciones vienen de una
/// tabla local genérica ya sincronizada (tbl_ubicaciones,
/// UbicacionesRepository), no hay endpoint nuevo.
///
/// A diferencia del original, al seleccionar hace `Navigator.pop(context,
/// ubicacion)` en vez de ida y vuelta por rutas — scan_product_screen.dart
/// espera el resultado con `Navigator.push`.
class RecepcionMultiusuarioLocationDestScreen extends StatefulWidget {
  const RecepcionMultiusuarioLocationDestScreen({super.key});

  @override
  State<RecepcionMultiusuarioLocationDestScreen> createState() =>
      _RecepcionMultiusuarioLocationDestScreenState();
}

class _RecepcionMultiusuarioLocationDestScreenState
    extends State<RecepcionMultiusuarioLocationDestScreen> {
  int? _selectedIndex;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RecepcionMultiusuarioLocationDestBloc>().add(
      const FetchUbicacionesDestEvent(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: primaryColorApp,
      body: SafeArea(
        child: Container(
          color: white,
          width: size.width,
          height: size.height,
          child: Column(
            children: [
              const _Header(),
              const SizedBox(height: 5),
              BlocBuilder<
                RecepcionMultiusuarioLocationDestBloc,
                RecepcionMultiusuarioLocationDestState
              >(
                builder: (context, state) {
                  final almacen = context
                      .read<RecepcionMultiusuarioLocationDestBloc>()
                      .selectedAlmacen;
                  return Text(
                    almacen == null || almacen.isEmpty
                        ? 'Ubicaciones de todos los almacenes'
                        : 'Ubicaciones del almacén: $almacen',
                    style: const TextStyle(
                      color: black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Card(
                  color: white,
                  elevation: 3,
                  child: TextFormField(
                    controller: _searchController,
                    style: const TextStyle(color: black, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: grey,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<RecepcionMultiusuarioLocationDestBloc>()
                              .add(const SearchUbicacionDestEvent(''));
                          FocusScope.of(context).unfocus();
                        },
                        icon: const Icon(Icons.close, color: grey, size: 20),
                      ),
                      hintText: 'Buscar ubicación',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      context.read<RecepcionMultiusuarioLocationDestBloc>().add(
                        SearchUbicacionDestEvent(value),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child:
                    BlocBuilder<
                      RecepcionMultiusuarioLocationDestBloc,
                      RecepcionMultiusuarioLocationDestState
                    >(
                      builder: (context, state) {
                        if (state is RecepcionMultiusuarioLocationDestLoading ||
                            state is RecepcionMultiusuarioLocationDestInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is RecepcionMultiusuarioLocationDestError) {
                          return Center(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: red, fontSize: 13),
                            ),
                          );
                        }

                        final ubicaciones =
                            state is RecepcionMultiusuarioLocationDestLoaded
                            ? state.ubicaciones
                            : const <ResultUbicaciones>[];

                        if (ubicaciones.isEmpty) {
                          return const Center(
                            child: Text(
                              'No se encontraron ubicaciones',
                              style: TextStyle(fontSize: 13, color: grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: ubicaciones.length,
                          itemBuilder: (context, index) {
                            final isSelected = _selectedIndex == index;
                            final ubicacion = ubicaciones[index];
                            final sinBarcode =
                                ubicacion.barcode == null ||
                                ubicacion.barcode == '' ||
                                ubicacion.barcode == 'false';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _selectedIndex = isSelected
                                      ? null
                                      : index,
                                ),
                                child: Card(
                                  elevation: 3,
                                  color: isSelected ? Colors.green[100] : white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'Nombre: ',
                                              style: TextStyle(
                                                color: black,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              ubicacion.name ?? '',
                                              style: TextStyle(
                                                color: primaryColorApp,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Text(
                                              'Barcode: ',
                                              style: TextStyle(
                                                color: black,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              sinBarcode
                                                  ? 'Sin barcode'
                                                  : ubicacion.barcode ?? '',
                                              style: TextStyle(
                                                color: sinBarcode
                                                    ? red
                                                    : primaryColorApp,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
              ),
              const SizedBox(height: 10),
              if (_selectedIndex != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      final state = context
                          .read<RecepcionMultiusuarioLocationDestBloc>()
                          .state;
                      if (state is! RecepcionMultiusuarioLocationDestLoaded) {
                        return;
                      }
                      if (_selectedIndex! >= state.ubicaciones.length) return;
                      Navigator.pop(
                        context,
                        state.ubicaciones[_selectedIndex!],
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: const Text(
                      'Seleccionar',
                      style: TextStyle(color: white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header con el mismo diseño que el resto de la app (contenedor redondeado
/// abajo + WarningWidgetCubit, en vez del AppBar de Material) y el menú "⋮"
/// para filtrar por almacén — réplica de _AppBarInfo en
/// locations_dest_widget.dart (recepción individual).
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: primaryColorApp,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      width: double.infinity,
      child: Column(
        children: [
          const WarningWidgetCubit(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'UBICACIONES',
                style: TextStyle(color: white, fontSize: 18),
              ),
              PopupMenuButton<String?>(
                color: white,
                icon: const Icon(Icons.more_vert, color: white, size: 20),
                onSelected: (value) {
                  context.read<RecepcionMultiusuarioLocationDestBloc>().add(
                    FilterUbicacionesAlmacenEvent(value),
                  );
                },
                itemBuilder: (context) {
                  final almacenes = context.read<UserBloc>().almacenes;
                  return [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.select_all,
                            color: primaryColorApp,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Todos los almacenes',
                            style: TextStyle(color: black, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ...almacenes.map(
                      (almacen) => PopupMenuItem<String?>(
                        value: almacen.name,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.file_upload_outlined,
                              color: primaryColorApp,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              almacen.name ?? '',
                              style: const TextStyle(
                                color: black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
