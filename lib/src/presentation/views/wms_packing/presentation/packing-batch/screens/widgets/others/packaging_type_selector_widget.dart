import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Selector de tipo de empaque del diálogo de empacar.
///
/// - **Escáner:** al abrir, el foco queda en un campo oculto de escaneo
///   ([BarcodeScannerField], sin teclado en pantalla). El código leído se
///   compara con el `barcode` de cada tipo: si coincide se selecciona; si no,
///   se avisa solo con [onInvalidScan] (sonido y vibración, sin mensajes). El
///   foco se queda en el escáner.
/// - **Búsqueda manual:** el campo visible filtra por nombre o por código de
///   barras. Al tocarlo toma el foco (y sale el teclado); para volver al
///   escáner se toca el icono de escáner junto al campo.
/// - Si ningún tipo tiene código de barras no hay nada que validar: el
///   escáner queda desactivado.
class PackagingTypeSelector extends StatefulWidget {
  const PackagingTypeSelector({
    super.key,
    required this.types,
    required this.selected,
    required this.onSelected,
    this.onInvalidScan,
  });

  final List<PackagingType> types;
  final PackagingType? selected;
  final ValueChanged<PackagingType> onSelected;

  /// Código escaneado que no pertenece a ningún tipo (sonido y vibración).
  final VoidCallback? onInvalidScan;

  @override
  State<PackagingTypeSelector> createState() => _PackagingTypeSelectorState();
}

class _PackagingTypeSelectorState extends State<PackagingTypeSelector> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocus = FocusNode();
  String _query = '';

  /// Solo tiene sentido escanear si algún tipo trae código de barras.
  bool get _canScan => widget.types.any((t) => t.barcode.trim().isNotEmpty);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scanController.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  List<PackagingType> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.types;
    return widget.types
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              (t.barcode.isNotEmpty && t.barcode.toLowerCase().contains(q)),
        )
        .toList();
  }

  /// Código leído por el escáner: selecciona el tipo con ese `barcode`.
  void _onScanned(String value, BuildContext context) {
    final code = value.trim().toLowerCase();
    if (code.isEmpty) return;
    for (final t in widget.types) {
      if (t.barcode.trim().isNotEmpty &&
          t.barcode.trim().toLowerCase() == code) {
        widget.onSelected(t);
        return;
      }
    }
    widget.onInvalidScan?.call();
  }

  /// Vuelve al modo escáner: quita el foco del buscador y oculta el teclado.
  void _focusScanner() {
    if (!_canScan) return;
    _searchFocus.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _scanFocus.requestFocus();
  }

  void _clear() {
    _searchController.clear();
    setState(() => _query = '');
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, size: 15, color: primaryColorApp),
            const SizedBox(width: 6),
            const Flexible(
              flex: 3,
              child: Text.rich(
                TextSpan(
                  text: 'TIPO DE EMPAQUE',
                  children: [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFF43F5E)),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.selected != null)
              Flexible(
                flex: 2,
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColorApp.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: primaryColorApp.withOpacity(0.25),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.selected!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryColorApp,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Escáner de la PDA (campo invisible, sin teclado). Toma el foco al
        // abrir el diálogo; solo existe si algún tipo trae código de barras.
        if (_canScan)
          BarcodeScannerField(
            key: const ValueKey('packaging_scanner'),
            controller: _scanController,
            focusNode: _scanFocus,
            onBarcodeScanned: _onScanned,
            clearOnScan: true,
            refocusOnScan: true,
            autofocus: true,
          ),
        // IntrinsicHeight: el selector vive dentro de un scroll (altura sin
        // límite) y `stretch` necesita una altura acotada.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('packaging_search'),
                  controller: _searchController,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Escanear o buscar empaque...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.cancel, size: 16),
                            color: const Color(0xFF94A3B8),
                            onPressed: _clear,
                            tooltip: 'Limpiar búsqueda',
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: primaryColorApp,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Icono de escáner: devuelve el foco al escáner (y oculta el
              // teclado). Resaltado cuando el escáner tiene el foco; apagado si
              // ningún tipo tiene código de barras.
              ListenableBuilder(
                listenable: _scanFocus,
                builder: (context, _) {
                  final canScan = _canScan;
                  final active = canScan && _scanFocus.hasFocus;
                  return Tooltip(
                    message: canScan
                        ? 'Escanear código de empaque'
                        : 'Ningún tipo de empaque tiene código de barras',
                    child: Material(
                      color: !canScan
                          ? const Color(0xFFE2E8F0)
                          : active
                          ? primaryColorApp
                          : primaryColorApp.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: canScan ? _focusScanner : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 22,
                            color: !canScan
                                ? const Color(0xFF94A3B8)
                                : active
                                ? white
                                : primaryColorApp,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: Text(
                'Opciones disponibles:',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Toca para seleccionar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No se encontró el tipo de empaque.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFF43F5E),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 192),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final type = filtered[index];
                return _PackagingTypeCard(
                  type: type,
                  selected: widget.selected == type,
                  onTap: () => widget.onSelected(type),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PackagingTypeCard extends StatelessWidget {
  const _PackagingTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final PackagingType type;
  final bool selected;
  final VoidCallback onTap;

  /// Icono según el nombre del tipo (los tipos vienen del backend).
  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('pallet') || n.contains('estiba')) {
      return Icons.grid_view_rounded;
    }
    if (n.contains('bobina')) return Icons.album_outlined;
    if (n.contains('bulto')) return Icons.shopping_bag_outlined;
    if (n.contains('fardo') || n.contains('paquete')) {
      return Icons.inventory_outlined;
    }
    if (n.contains('sin')) return Icons.block;
    return Icons.inventory_2_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? primaryColorApp.withOpacity(0.07) : white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primaryColorApp : const Color(0xFFE2E8F0),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? primaryColorApp : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconFor(type.name),
                  size: 16,
                  color: selected ? white : primaryColorApp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? primaryColorApp : const Color(0xFF334155),
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? primaryColorApp : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
