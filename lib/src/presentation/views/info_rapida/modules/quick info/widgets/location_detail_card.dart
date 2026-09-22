import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/info_rapida_model.dart';

/// Tarjeta maestra del detalle de ubicación: identificación (nombre,
/// barcode) editable, jerarquía (padre/tipo) de solo lectura y el botón
/// "Actualizar" cuando está en modo edición.
class LocationDetailCard extends StatelessWidget {
  final InfoResult ubicacion;
  final bool isEditMode;
  final TextEditingController nameController;
  final TextEditingController barcodeController;
  final VoidCallback onSubmitUpdate;

  const LocationDetailCard({
    super.key,
    required this.ubicacion,
    required this.isEditMode,
    required this.nameController,
    required this.barcodeController,
    required this.onSubmitUpdate,
  });

  static const _typeLabels = {
    'internal': 'Interna / Existencias',
    'customer': 'Cliente',
    'supplier': 'Proveedor',
    'transit': 'Tránsito',
    'inventory': 'Ajuste de inventario',
    'view': 'Vista',
    'production': 'Producción',
  };

  void _copy(BuildContext context, String value, String label) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = ubicacion.tipoUbicacion;
    final typeLabel = _typeLabels[type] ?? (type ?? 'Desconocido');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'UBICACIÓN FÍSICA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColorApp.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColorApp.withOpacity(0.2)),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColorApp,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _EditableField(
                  label: 'Nombre',
                  controller: nameController,
                  editable: isEditMode,
                  onCopy: isEditMode
                      ? null
                      : () => _copy(context, nameController.text, 'Nombre'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EditableField(
                  label: 'Barcode',
                  controller: barcodeController,
                  editable: isEditMode,
                  monospace: true,
                  onCopy: isEditMode
                      ? null
                      : () => _copy(context, barcodeController.text, 'Barcode'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaChip(
                  label: 'Ubicación padre',
                  value: ubicacion.ubicacionPadre ?? 'Sin nombre',
                ),
                const SizedBox(height: 4),
                _MetaChip(
                  label: 'Ubicación tipo',
                  value: type ?? 'N/A',
                  mono: true,
                ),
              ],
            ),
          ),
          if (isEditMode) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmitUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  foregroundColor: white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ACTUALIZAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool editable;
  final bool monospace;
  final VoidCallback? onCopy;

  const _EditableField({
    required this.label,
    required this.controller,
    required this.editable,
    this.monospace = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: editable ? white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: editable
              ? primaryColorApp.withOpacity(0.4)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryColorApp,
                  ),
                ),
              ),
              if (onCopy != null)
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
            ],
          ),
          editable
              ? TextFormField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: monospace ? 'monospace' : null,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                )
              : Text(
                  controller.text.isEmpty ? 'Sin dato' : controller.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: monospace ? 'monospace' : null,
                    color: Colors.grey.shade900,
                  ),
                ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _MetaChip({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primaryColorApp,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: mono ? 'monospace' : null,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
