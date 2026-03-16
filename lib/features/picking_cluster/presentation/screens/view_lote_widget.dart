import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/scan_product_scree.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/lote_producto.dart';

class ViewLoteScreen extends StatefulWidget {
  final List<LoteProducto> lotes;
  final int? suggestedLoteId;

  const ViewLoteScreen({
    super.key,
    required this.lotes,
    this.suggestedLoteId,
  });

  @override
  State<ViewLoteScreen> createState() => _ViewLoteScreenState();
}

class _ViewLoteScreenState extends State<ViewLoteScreen> {
  int? selectedIndex;

  List<LoteProducto> allLotes = [];
  List<LoteProducto> filteredLotes = [];

  late final TextEditingController searchController;
  late final FocusNode searchFocusNode;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();

    // Arrange the lots array to move the suggested lot to index 0, if provided
    var initialLotes = List<LoteProducto>.from(widget.lotes);
    if (widget.suggestedLoteId != null) {
      final suggestedLoteIndex =
          initialLotes.indexWhere((lote) => lote.id == widget.suggestedLoteId);
      if (suggestedLoteIndex != -1) {
        final suggestedLote = initialLotes.removeAt(suggestedLoteIndex);
        initialLotes.insert(0, suggestedLote);
      }
    }

    allLotes = initialLotes;
    filteredLotes = List.from(allLotes);
  }

  void _filterLotes(String query) {
    final q = query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? List<LoteProducto>.from(allLotes)
        : allLotes
            .where((lote) => (lote.name ?? '').toLowerCase().contains(q))
            .toList();
    // Use setState only for the list data — not in a way that rebuilds the
    // FocusNode ancestor, so the keyboard stays open.
    setState(() {
      filteredLotes = filtered;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: GestureDetector(
        // Tap outside the field closes the keyboard
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          // resizeToAvoidBottomInset: true (default) allows the keyboard to
          // push the body up without tearing the widget tree.
          backgroundColor: white,
          body: SafeArea(
            child: Column(
              children: [
                const WarningWidgetCubit(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: primaryColorApp,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  width: double.infinity,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, 'scan-product-cluster');
                        },
                        icon: const Icon(Icons.arrow_back, color: white),
                      ),
                      const Spacer(),
                      const Text(
                        'Seleccionar Lote',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: white),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                // ── Search bar ───────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    child: TextField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      showCursor: true,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(color: black, fontSize: 14),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          color: grey,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            searchController.clear();
                            _filterLotes('');
                            searchFocusNode.unfocus();
                          },
                          icon: const Icon(
                            Icons.close,
                            color: grey,
                            size: 20,
                          ),
                        ),
                        hintText: 'Buscar lote',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _filterLotes,
                    ),
                  ),
                ),

                // ── Lot list ─────────────────────────────────────────────
                if (allLotes.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No hay lotes disponibles',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.manual,
                      itemCount: filteredLotes.length,
                      itemBuilder: (context, index) {
                        final loteData = filteredLotes[index];
                        final bool isSelected = selectedIndex == index;
                        final bool isSuggested =
                            widget.suggestedLoteId != null &&
                                loteData.id == widget.suggestedLoteId;
                        final rawDate = loteData.expirationDate;
                        bool isExpired = false;
                        int? daysLeft;

                        if (rawDate != null &&
                            rawDate != false &&
                            rawDate.toString().isNotEmpty) {
                          final expiration =
                              DateTime.tryParse(rawDate.toString());
                          if (expiration != null) {
                            final now = DateTime.now();
                            final dateExpiration = DateTime(expiration.year,
                                expiration.month, expiration.day);
                            final dateNow =
                                DateTime(now.year, now.month, now.day);
                            final difference =
                                dateExpiration.difference(dateNow).inDays;
                            if (difference < 0) {
                              isExpired = true;
                            } else {
                              daysLeft = difference;
                            }
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 0),
                          child: GestureDetector(
                            onTap: () {
                              // Unfocus first so the keyboard closes cleanly
                              searchFocusNode.unfocus();
                              setState(() {
                                selectedIndex = isSelected ? null : index;
                              });
                            },
                            child: Card(
                              elevation: 3,
                              color:
                                  isSelected ? Colors.green[100] : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Lote: ${loteData.name}',
                                          style: const TextStyle(
                                              color: primaryColorApp,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (isSuggested) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: Colors.green.shade300),
                                            ),
                                            child: const Text('Sugerido',
                                                style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ]
                                      ],
                                    ),
                                    if (rawDate != null && rawDate != '') ...[
                                      Row(
                                        children: [
                                          const Text('Fecha de caducidad: ',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12)),
                                          Text(
                                            rawDate == false
                                                ? 'Sin fecha'
                                                : '$rawDate',
                                            style: TextStyle(
                                              color: (rawDate == false ||
                                                      isExpired)
                                                  ? Colors.red
                                                  : Colors.black,
                                              fontSize: 12,
                                              fontWeight: isExpired
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (isExpired) ...[
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.warning_amber_rounded,
                                                color: Colors.red, size: 16),
                                            SizedBox(width: 5),
                                            Text('¡LOTE VENCIDO!',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ] else if (daysLeft != null) ...[
                                      const SizedBox(height: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: daysLeft < 15
                                              ? Colors.orange[50]
                                              : Colors.blue[50],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: daysLeft < 15
                                                ? Colors.orange.shade300
                                                : Colors.blue.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.av_timer,
                                              color: daysLeft < 15
                                                  ? Colors.orange[800]
                                                  : Colors.blue[700],
                                              size: 16,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              daysLeft == 0
                                                  ? 'Vence hoy'
                                                  : 'Vence en $daysLeft días',
                                              style: TextStyle(
                                                color: daysLeft < 15
                                                    ? Colors.orange[900]
                                                    : Colors.blue[900],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // ── Confirm button ────────────────────────────────────────
                if (selectedIndex != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedLote = filteredLotes[selectedIndex!];

                        //validamos que el lote seleccionado sea el mismo que el sugerido
                        if (selectedLote.id == widget.suggestedLoteId) {
                          context.read<ClusterPickingBloc>().add(
                              ValidateFieldsEvent(field: "lote", isOk: true));
                          context
                              .read<ClusterPickingBloc>()
                              .add(SelectLoteEventCluster(selectedLote));
                          Navigator.pushReplacementNamed(
                              context, 'scan-product-cluster');
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => DialogValidateLot(
                              bloc: context.read<ClusterPickingBloc>(),
                              selectedLote: selectedLote,
                              onLoteSelectedWithValidate: (lote) {
                                context
                                    .read<ClusterPickingBloc>()
                                    .add(SelectLoteEventCluster(lote));

                                Navigator.pushReplacementNamed(
                                    context, 'scan-product-cluster');
                              },
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Seleccionar lote',
                          style: TextStyle(color: white)),
                    ),
                  ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
