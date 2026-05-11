import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/entities/printer.dart';
import '../../domain/entities/printer_report.dart';
import '../bloc/printing_bloc.dart';

class ModalPrintersList extends StatefulWidget {
  final List<dynamic> resIds;
  final String? model;
  final dynamic companyId;

  const ModalPrintersList({
    super.key,
    required this.resIds,
    this.model,
    required this.companyId,
  });

  static Future<void> show(
    BuildContext context, {
    required List<dynamic> resIds,
    String? model,
    required dynamic companyId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ModalPrintersList(resIds: resIds, model: model, companyId: companyId),
    );
  }

  @override
  State<ModalPrintersList> createState() => _ModalPrintersListState();
}

class _ModalPrintersListState extends State<ModalPrintersList> {
  int _copies = 1;

  @override
  void initState() {
    super.initState();
    context.read<PrintingBloc>().add(LoadPrintersEvent());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<PrintingBloc, PrintingState>(
      listener: (context, state) {
        if (state is PrintSuccess) {
          Get.snackbar(
            "360 Software Informa",
            state.message,
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.green),
          );
        } else if (state is PrintError) {
          Get.snackbar(
            "360 Software Informa",
            state.message,
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: GestureDetector(
              onTap: () {}, // absorbe taps para no perder el foco
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
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.copy_outlined,
                            color: primaryColorApp, size: 20),
                        const SizedBox(width: 8),
                        const Text('Copias:',
                            style: TextStyle(
                                fontSize: 15, color: primaryColorApp)),
                        const Spacer(),
                        IconButton(
                          onPressed: _copies > 1
                              ? () => setState(() => _copies--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: primaryColorApp,
                          disabledColor: grey,
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$_copies',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColorApp),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _copies++),
                          icon: const Icon(Icons.add_circle_outline),
                          color: primaryColorApp,
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
                                const Icon(Icons.error_outline,
                                    color: red, size: 48),
                                const SizedBox(height: 16),
                                Text(state.message,
                                    textAlign: TextAlign.center),
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
                          final List<Printer> printerList =
                              (state is PrintersLoaded)
                                  ? state.printers
                                  : (state is PrintSuccess)
                                      ? state.printers
                                      : context.read<PrintingBloc>().printers;

                          if (printerList.isEmpty) {
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
                                resIds: widget.resIds,
                                model: widget.model,
                                companyId: widget.companyId,
                                copies: _copies,
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
          ),
        ),
      ),
    );
  }
}

class _PrinterExpansionTile extends StatelessWidget {
  final Printer printer;
  final List<dynamic> resIds;
  final String? model;
  final dynamic companyId;
  final int copies;

  const _PrinterExpansionTile({
    required this.printer,
    required this.resIds,
    this.model,
    required this.companyId,
    required this.copies,
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
            resIds: resIds,
            model: model,
            companyId: companyId,
            copies: copies,
          );
        }).toList(),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final Printer printer;
  final PrinterReport report;
  final List<dynamic> resIds;
  final String? model;
  final dynamic companyId;
  final int copies;

  const _ReportTile({
    required this.printer,
    required this.report,
    required this.resIds,
    this.model,
    required this.companyId,
    required this.copies,
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
                        Get.back();
                        context
                            .read<PrintingBloc>()
                            .add(SelectPrinterEvent(printer));
                        context
                            .read<PrintingBloc>()
                            .add(SelectReportEvent(report));
                        context.read<PrintingBloc>().add(ExecutePrintEvent(
                            resIds: List<int>.from(resIds),
                            companyId: int.parse(companyId.toString()),
                            copies: copies));
                        print(printer.hostmachine);
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
                : const Icon(
                    Icons.print_outlined,
                    color: primaryColorApp,
                  ),
          ),
        );
      },
    );
  }
}
