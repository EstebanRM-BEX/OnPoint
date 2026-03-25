import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/entities/printer.dart';
import '../../domain/entities/printer_report.dart';
import '../bloc/printing_bloc.dart';

class DialogPrinterSelector extends StatefulWidget {
  final int resId;
  final String model;

  const DialogPrinterSelector({
    super.key,
    required this.resId,
    required this.model,
  });

  static Future<void> show(BuildContext context,
      {required int resId, required String model}) {
    return showDialog(
      context: context,
      builder: (context) => DialogPrinterSelector(resId: resId, model: model),
    );
  }

  @override
  State<DialogPrinterSelector> createState() => _DialogPrinterSelectorState();
}

class _DialogPrinterSelectorState extends State<DialogPrinterSelector> {
  @override
  void initState() {
    super.initState();
    context.read<PrintingBloc>().add(LoadPrintersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PrintingBloc, PrintingState>(
      listener: (context, state) {
        if (state is PrintSuccess) {
          Get.snackbar(
            'Éxito',
            state.message,
            backgroundColor: green,
            colorText: white,
            snackPosition: SnackPosition.BOTTOM,
          );
          Navigator.of(context).pop();
        } else if (state is PrintError) {
          Get.snackbar(
            'Error',
            state.message,
            backgroundColor: red,
            colorText: white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<PrintingBloc>();

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Seleccionar Impresora',
            style: TextStyle(
              color: primaryColorApp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state is PrintersLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is PrintersError)
                  Text('Error: ${state.message}', style: const TextStyle(color: red))
                else if (state is PrintersLoaded ||
                    state is PrintingInProgress ||
                    state is PrintError ||
                    state is PrintSuccess)
                  _buildContent(bloc, state is PrintersLoaded ? state.printers : []),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: grey)),
            ),
            ElevatedButton(
              onPressed: (bloc.selectedPrinter != null &&
                      bloc.selectedReport != null &&
                      state is! PrintingInProgress)
                  ? () => bloc.add(ExecutePrintEvent(resId: widget.resId))
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: state is PrintingInProgress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: white,
                      ),
                    )
                  : const Text('Imprimir', style: TextStyle(color: white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(PrintingBloc bloc, List<Printer> printers) {
    // If we're in a loading/error state but had printers before, we might want to keep showing them.
    // For now, let's assume printers is correctly passed or we use bloc.selectedPrinter.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Impresora:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Printer>(
          value: bloc.selectedPrinter,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: printers.map((printer) {
            return DropdownMenuItem(
              value: printer,
              child: Text(printer.printerName),
            );
          }).toList(),
          onChanged: (value) => bloc.add(SelectPrinterEvent(value)),
          hint: const Text('Seleccione impresora'),
        ),
        const SizedBox(height: 16),
        if (bloc.selectedPrinter != null) ...[
          const Text('Reporte:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<PrinterReport>(
            value: bloc.selectedReport,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: bloc.selectedPrinter!.availableReports.map((report) {
              return DropdownMenuItem(
                value: report,
                child: Text(report.name),
              );
            }).toList(),
            onChanged: (value) => bloc.add(SelectReportEvent(value)),
            hint: const Text('Seleccione reporte'),
          ),
        ],
      ],
    );
  }
}
