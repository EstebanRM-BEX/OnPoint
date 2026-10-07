import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Barra unificada de búsqueda manual y escaneo para Packing, con el mismo
/// diseño y comportamiento que el SearchDock de Picking Cluster.
///
/// Aloja el campo invisible del escáner ([scanner]) en segundo plano sin ocupar
/// espacio visible, un campo de búsqueda estilizado con prefijo y botón de
/// limpiar, soporte para acciones adicionales (como selección múltiple) y un
/// botón de activación que refleja el foco activo del lector PDA.
class PackSearchDock extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode searchFocusNode;
  final FocusNode scannerFocusNode;
  final Widget scanner;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;
  final VoidCallback onActivateScanner;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final Widget? action;
  final bool? isScannerActive;

  const PackSearchDock({
    super.key,
    required this.controller,
    required this.searchFocusNode,
    required this.scannerFocusNode,
    required this.scanner,
    required this.onChanged,
    required this.onCleared,
    required this.onActivateScanner,
    this.onSubmitted,
    this.hintText = 'Escanear o buscar producto...',
    this.action,
    this.isScannerActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
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
              if (action != null) ...[
                const SizedBox(width: 8),
                action!,
              ],
              const SizedBox(width: 8),
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
          onSubmitted: onSubmitted,
          // Forzar despliegue de teclado en PDAs si estuviese oculto
          onTap: () => SystemChannels.textInput.invokeMethod('TextInput.show'),
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF94A3B8),
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
                color: primaryColorApp,
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
        final active = isScannerActive ?? scannerFocusNode.hasFocus;
        return Tooltip(
          message: active ? 'Lector activo' : 'Activar lector',
          child: Material(
            color: active ? primaryColorApp : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(12),
            elevation: active ? 4 : 0,
            shadowColor: primaryColorApp.withOpacity(0.4),
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
