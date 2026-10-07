import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/packages/packing_packages_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Lista de ubicaciones de muelle con buscador. Devuelve la elegida.
Future<UbicacionMuelle?> showUbicacionMuelleSheet(
  BuildContext context,
  PackingPackagesBloc bloc,
) {
  bloc
    ..add(const UbicacionesMuellePackCargadas())
    ..add(const BusquedaUbicacionPackCambiada(''));
  return showModalBottomSheet<UbicacionMuelle>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        BlocProvider.value(value: bloc, child: const _UbicacionMuelleSheet()),
  );
}

class _UbicacionMuelleSheet extends StatefulWidget {
  const _UbicacionMuelleSheet();

  @override
  State<_UbicacionMuelleSheet> createState() => _UbicacionMuelleSheetState();
}

class _UbicacionMuelleSheetState extends State<_UbicacionMuelleSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PackingPackagesBloc>();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'Ubicación de destino',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColorApp,
              ),
            ),
            DynamicSearchBar(
              controller: _controller,
              hintText: 'Buscar ubicación',
              closeKeyboardOnClear: false,
              onSearchChanged: (v) =>
                  bloc.add(BusquedaUbicacionPackCambiada(v)),
              onSearchCleared: () =>
                  bloc.add(const BusquedaUbicacionPackCambiada('')),
            ),
            Expanded(
              child: BlocBuilder<PackingPackagesBloc, PackingPackagesState>(
                builder: (context, state) {
                  final ubicaciones = state.ubicacionesVisibles;
                  if (ubicaciones.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay ubicaciones de muelle',
                        style: TextStyle(color: grey),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: ubicaciones.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final u = ubicaciones[i];
                      return ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: primaryColorApp,
                        ),
                        title: Text(
                          u.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          [
                            u.barcode,
                            u.warehouseName,
                          ].where((e) => e.isNotEmpty).join(' · '),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => Navigator.pop(context, u),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
