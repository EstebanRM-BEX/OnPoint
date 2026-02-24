import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/sounds_utils.dart';
import 'package:wms_app/core/utils/vibrate_utils.dart';
import 'package:wms_app/features/picking/presentation/bloc/cluster_picking_bloc.dart';
import 'package:wms_app/shared/widgets/custom_header_widget.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

class PickingClusterScreen extends StatefulWidget {
  const PickingClusterScreen({super.key});

  @override
  State<PickingClusterScreen> createState() => _PickingClusterScreenState();
}

class _PickingClusterScreenState extends State<PickingClusterScreen> {
  final AudioService _audioService = AudioService();
  final VibrationService _vibrationService = VibrationService();
  FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();

  void validateBarcode(String value, BuildContext context) {
    final barcode = _controllerToDo.text.isEmpty ? value : _controllerToDo.text;
    _controllerToDo.clear();
    context.read<ClusterPickingBloc>().add(ScanBarcodeEvent(barcode));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocListener<ClusterPickingBloc, ClusterPickingState>(
        listener: (context, state) {
          if (state is ScanError) {
            _audioService.playErrorSound();
            _vibrationService.vibrate();
          } else if (state is ScanSuccess) {}
        },
        child: Scaffold(
          backgroundColor: white,
          body: BlocBuilder<ClusterPickingBloc, ClusterPickingState>(
            builder: (context, state) {
              return Column(
                children: [
                  CustomHeaderWidget(
                    title: 'PICK CLUSTER',
                    onBack: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    onRefresh: () async {
                      // Implementar refresco de datos si fuera necesario
                    },
                    showCalendar: false,
                  ),
                  const SizedBox(height: 10),
                  BarcodeScannerField(
                    controller: _controllerToDo,
                    focusNode: focusNodeBuscar,
                    scannedValue5: "",
                    onBarcodeScanned: (value, context) {
                      validateBarcode(value, context);
                    },
                    onKeyScanned: (keyLabel, type, context) {
                      // Opcional: manejar entrada de teclado
                    },
                  ),
                  const Spacer(),
                  const Center(
                    child: Text(
                      'Escanee un código de barras para comenzar',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
