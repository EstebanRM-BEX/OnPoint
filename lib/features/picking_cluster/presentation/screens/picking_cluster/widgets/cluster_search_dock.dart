import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';

/// Buscador manual de batches + botón que reactiva el lector PDA.
///
/// [scanner] es el campo invisible del escáner (keyboard-wedge); se monta
/// detrás del buscador para que conserve el foco sin ocupar espacio. El
/// botón de código de barras refleja si ese foco está activo.
class ClusterSearchDock extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode searchFocusNode;
  final FocusNode scannerFocusNode;
  final Widget scanner;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;
  final VoidCallback onActivateScanner;

  const ClusterSearchDock({
    super.key,
    required this.controller,
    required this.searchFocusNode,
    required this.scannerFocusNode,
    required this.scanner,
    required this.onChanged,
    required this.onCleared,
    required this.onActivateScanner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ClusterPalette.slate200)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Opacity(opacity: 0, child: IgnorePointer(child: scanner)),
          ),
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 12),
              _buildScannerButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: searchFocusNode,
          onChanged: onChanged,
          // Algunos PDA cierran el IME entre toques: se fuerza al tocar.
          onTap: () => SystemChannels.textInput.invokeMethod('TextInput.show'),
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 13, color: ClusterPalette.slate800),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Escanear o buscar Batch...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: ClusterPalette.slate400,
            ),
            filled: true,
            fillColor: ClusterPalette.slate100,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: ClusterPalette.slate400,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: ClusterPalette.slate400,
                    ),
                    onPressed: onCleared,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ClusterPalette.brand500,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScannerButton() {
    return ListenableBuilder(
      listenable: scannerFocusNode,
      builder: (context, _) {
        final active = scannerFocusNode.hasFocus;
        return Tooltip(
          message: active ? 'Lector activo' : 'Activar lector',
          child: Material(
            color: active ? ClusterPalette.brand600 : ClusterPalette.slate300,
            borderRadius: BorderRadius.circular(12),
            elevation: active ? 4 : 0,
            shadowColor: ClusterPalette.brand600.withOpacity(0.4),
            child: InkWell(
              onTap: onActivateScanner,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
