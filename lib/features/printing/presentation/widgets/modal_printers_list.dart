import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/entities/printer.dart';
import '../../domain/entities/printer_report.dart';
import '../bloc/printing_bloc.dart';

class ModalPrintersList extends StatefulWidget {
  final int? resId;
  final String? model;

  const ModalPrintersList({super.key, this.resId, this.model});

  static Future<void> show(BuildContext context, {int? resId, String? model}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalPrintersList(resId: resId, model: model),
    );
  }

  @override
  State<ModalPrintersList> createState() => _ModalPrintersListState();
}

class _ModalPrintersListState extends State<ModalPrintersList> {
  @override
  void initState() {
    super.initState();
    context.read<PrintingBloc>().add(LoadPrintersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrintingBloc, PrintingState>(
      listener: (context, state) {
        if (state is PrintSuccess) {
          Get.snackbar("360 Software Informa", state.message,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.green));
        } else if (state is PrintError) {
          Get.snackbar("360 Software Informa", state.message,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red));
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.print_rounded,
                      color: primaryColorApp, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Impresoras Disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColorApp,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: grey),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: BlocBuilder<PrintingBloc, PrintingState>(
                builder: (context, state) {
                  if (state is PrintersLoading) {
                    return const Center(
                      child: Text('Cargando impresoras...'),
                    );
                  } else if (state is PrintersError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: red, size: 48),
                          const SizedBox(height: 16),
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context
                                .read<PrintingBloc>()
                                .add(LoadPrintersEvent()),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is PrintersLoaded ||
                      state is PrintingInProgress ||
                      state is PrintSuccess ||
                      state is PrintError) {
                    // Attempting to stay on the list even during printing
                    final List<Printer> printerList = (state is PrintersLoaded)
                        ? state.printers
                        : (state is PrintSuccess)
                            ? state.printers
                            : context.read<PrintingBloc>().printers;

                    // Note: If the state changes to PrintingInProgress, we might lose the 'printers' list
                    // if it's not carried over in all states. For now, let's assume PrintersLoaded is the steady state for the list.

                    if (printerList.isEmpty) {
                      // Fallback: search for printers in parent or bloc if needed
                      return const Center(
                          child: Text('No hay impresoras disponibles'));
                    }

                    return ListView.builder(
                      itemCount: printerList.length,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final printer = printerList[index];
                        return _PrinterExpansionTile(
                          printer: printer,
                          resId: widget.resId,
                          model: widget.model,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrinterExpansionTile extends StatelessWidget {
  final Printer printer;
  final int? resId;
  final String? model;

  const _PrinterExpansionTile({
    required this.printer,
    this.resId,
    this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: grey.withOpacity(0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: CircleAvatar(
          backgroundColor: primaryColorApp.withOpacity(0.1),
          child: const Icon(Icons.print, color: primaryColorApp),
        ),
        title: Text(
          printer.printerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Tipo: ${printer.printerType} | Host: ${printer.hostmachine}',
          style: const TextStyle(fontSize: 12, color: grey),
        ),
        children: printer.availableReports.map((report) {
          return _ReportTile(
            printer: printer,
            report: report,
            resId: resId,
            model: model,
          );
        }).toList(),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Printer printer;
  final PrinterReport report;
  final int? resId;
  final String? model;

  const _ReportTile({
    required this.printer,
    required this.report,
    this.resId,
    this.model,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrintingBloc, PrintingState>(
      builder: (context, state) {
        final isPrintingThis = state is PrintingInProgress &&
            context.read<PrintingBloc>().selectedReport == report &&
            context.read<PrintingBloc>().selectedPrinter == printer;

        return ListTile(
          contentPadding: const EdgeInsets.only(left: 70, right: 16),
          title: Text(report.name, style: const TextStyle(fontSize: 14)),
          subtitle: Text(report.reportName,
              style: const TextStyle(fontSize: 10, color: grey)),
          trailing: IconButton(
            onPressed: (state is! PrintingInProgress)
                ? () {
                    Get.defaultDialog(
                      title: 'Confirmación',
                      middleText:
                          '¿Desea imprimir el reporte "${report.name}" en la impresora "${printer.printerName}"?',
                      textConfirm: 'Si, Imprimir',
                      textCancel: 'Cancelar',
                      confirmTextColor: white,
                      buttonColor: primaryColorApp,
                      onConfirm: () {
                        Get.back(); // Close the confirmation dialog
                        context
                            .read<PrintingBloc>()
                            .add(SelectPrinterEvent(printer));
                        context
                            .read<PrintingBloc>()
                            .add(SelectReportEvent(report));
                        context
                            .read<PrintingBloc>()
                            .add(ExecutePrintEvent(resId: resId ?? 0));
                        //mostrar informacion de la impresora
                        print(printer.printerName);
                        print(printer.printerType);
                        print(printer.hostmachine);
                        print('reporte: ${report.name}');
                        print('reporte: ${report.reportName}');
                        print('reporte: ${report.id}');
                        print('reporte: ${report.reportType}');
                        print('reporte: ${report.model}');
                      },
                    );
                  }
                : null,
            icon: isPrintingThis
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.print_outlined,
                    color: primaryColorApp,
                  ),
          ),
        );
      },
    );
  }
}
