import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/wms_picking/models/submeuelle_model.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Pick/bloc/picking_pick_bloc.dart';

class SelectSubMuelleBottomSheetPick extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const SelectSubMuelleBottomSheetPick({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<SelectSubMuelleBottomSheetPick> createState() =>
      _SelectSubMuelleBottomSheetState();
}

class _SelectSubMuelleBottomSheetState
    extends State<SelectSubMuelleBottomSheetPick> {
  bool? isOccupied; // null = no seleccionado, true = ocupado, false = libre

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PickingPickBloc, PickingPickState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.only(bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccione la sub ubicación de destino para los productos',
                style: TextStyle(fontSize: 12, color: primaryColorApp),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: context.read<PickingPickBloc>().submuelles.length,
                  itemBuilder: (context, index) {
                    final muelle =
                        context.read<PickingPickBloc>().submuelles[index];
                    bool isSelected = muelle ==
                        context.read<PickingPickBloc>().subMuelleSelected;

                    return GestureDetector(
                      onTap: () {
                        context
                            .read<PickingPickBloc>()
                            .add(SelectedSubMuelleEvent(muelle));
                      },
                      child: Card(
                        color: isSelected
                            ? isOccupied == true
                                ? Colors.red[300]
                                : isOccupied == false
                                    ? Colors.green[300]
                                    : primaryColorAppLigth
                            : Colors.white,
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                muelle.completeName ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 5),

              /// 🔵 Selección exclusiva: ocupado o libre
              Center(
                child: Text('Estado del submuelle',
                    style: TextStyle(fontSize: 12, color: primaryColorApp)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: isOccupied == true,
                    onChanged: (value) {
                      setState(() {
                        isOccupied = value == true ? true : null;
                      });
                    },
                  ),
                  const Text(
                    'Lleno',
                    style: TextStyle(fontSize: 13, color: black),
                  ),
                  const SizedBox(width: 20),
                  Checkbox(
                    value: isOccupied == false,
                    onChanged: (value) {
                      setState(() {
                        isOccupied = value == true ? false : null;
                      });
                    },
                  ),
                  const Text(
                    'Libre',
                    style: TextStyle(fontSize: 13, color: black),
                  ),
                ],
              ),
              Visibility(
                  visible: isOccupied != null,
                  child: Text(
                    isOccupied == true
                        ? 'Use esta opción solo si el submuelle está completamente ocupado'
                        : 'Use esta opción solo si el submuelle está parcial o completamente libre',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: black,
                    ),
                  )),
              const SizedBox(height: 10),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.read<PickingPickBloc>().subMuelleSelected =
                            Muelles();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 12, color: white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: (context
                                      .read<PickingPickBloc>()
                                      .subMuelleSelected
                                      .completeName ==
                                  null ||
                              isOccupied == null)
                          ? null
                          : () {
                              debugPrint(
                                  'Estado del submuelle: ${isOccupied == true ? "Ocupado" : "Libre"}');

                              context
                                  .read<PickingPickBloc>()
                                  .add(AssignSubmuelleEvent(
                                    context
                                        .read<PickingPickBloc>()
                                        .filteredProducts
                                        .where((e) {
                                      return (e.isSeparate == 1) &&
                                          (e.locationDestId ==
                                              context
                                                  .read<PickingPickBloc>()
                                                  .pickWithProducts
                                                  .pick
                                                  ?.muelle);
                                    }).toList(),
                                    context
                                        .read<PickingPickBloc>()
                                        .subMuelleSelected,
                                    isOccupied == null ? false : isOccupied!,
                                  ));

                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(fontSize: 12, color: white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
