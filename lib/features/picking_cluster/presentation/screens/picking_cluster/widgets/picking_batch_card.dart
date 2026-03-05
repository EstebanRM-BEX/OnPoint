import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import '../../../../domain/entities/picking_batch.dart';
import 'package:intl/intl.dart';

class PickingBatchCard extends StatelessWidget {
  final PickingBatch batch;
  final VoidCallback onTap;

  const PickingBatchCard({
    super.key,
    required this.batch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        child: Card(
          elevation: 3,
          child: ListTile(
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: primaryColorApp,
            ),
            leading: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),

                  //sombras
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2))
                  ]),
              child: Image.asset(
                "assets/icons/producto.png",
                color: primaryColorApp,
                width: 24,
              ),
            ),
            title: Text(batch.name ?? '', style: const TextStyle(fontSize: 14)),
            subtitle: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(batch.zonaEntrega ?? '',
                      style: const TextStyle(fontSize: 12, color: black)),
                ),
                Row(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Tipo de operación:",
                          style: TextStyle(fontSize: 12, color: grey)),
                    ),
                    const Spacer(),
                    batch.startTimePick != ""
                        ? GestureDetector(
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) => DialogInfo(
                                        title: 'Tiempo de inicio',
                                        body:
                                            'Este batch fue iniciado a las ${batch.startTimePick}',
                                      ));
                            },
                            child: Icon(
                              Icons.timer_sharp,
                              color: primaryColorApp,
                              size: 15,
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    batch.pickingTypeId.toString(),
                    style: TextStyle(fontSize: 12, color: primaryColorApp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_sharp,
                        color: primaryColorApp,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        batch.scheduledDate != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(DateTime.parse(batch.scheduledDate!))
                            : "Sin fecha",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: primaryColorApp,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Cantidad de lineas: ",
                        style: TextStyle(fontSize: 12, color: black),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Expanded(
                        child: Text(
                          batch.countItems.toString(),
                          style:
                              TextStyle(fontSize: 12, color: primaryColorApp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: primaryColorApp,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Cantidad unidades: ",
                        style: TextStyle(fontSize: 12, color: black),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Expanded(
                        child: Text(
                          batch.totalQuantityItems.toString(),
                          style:
                              TextStyle(fontSize: 12, color: primaryColorApp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: primaryColorApp,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          batch.userName ?? "Sin responsable",
                          style: const TextStyle(fontSize: 12, color: black),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
