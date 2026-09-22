import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/info_rapida_model.dart';

/// Tarjeta maestra del detalle de producto: identificación (foto, nombre,
/// referencia, categoría) siempre visible + especificaciones técnicas
/// colapsables (KPIs de stock, atributos, código de barras). En modo edición
/// los atributos se vuelven campos editables; fuera de edición, el código de
/// barras se puede copiar con un toque.
class ProductDetailCard extends StatelessWidget {
  final InfoResult product;
  final bool isEditMode;
  final bool isExpanded;
  final TextEditingController nameController;
  final TextEditingController referenceController;
  final TextEditingController priceController;
  final TextEditingController pesoController;
  final TextEditingController volumenController;
  final TextEditingController barcodeController;
  final VoidCallback onViewImage;
  final VoidCallback onToggleExpanded;
  final VoidCallback onSubmitUpdate;

  const ProductDetailCard({
    super.key,
    required this.product,
    required this.isEditMode,
    required this.isExpanded,
    required this.nameController,
    required this.referenceController,
    required this.priceController,
    required this.pesoController,
    required this.volumenController,
    required this.barcodeController,
    required this.onViewImage,
    required this.onToggleExpanded,
    required this.onSubmitUpdate,
  });

  void _copyBarcode(BuildContext context) {
    final code = product.codigoBarras?.toString() ?? '';
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onViewImage,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryColorApp.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColorApp.withOpacity(0.15)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, color: primaryColorApp, size: 26),
                        const SizedBox(height: 2),
                        Text(
                          'Foto',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: primaryColorApp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColorApp.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColorApp.withOpacity(0.2)),
                        ),
                        child: Text(
                          'REF: ${product.referencia ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: primaryColorApp,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      isEditMode
                          ? TextFormField(
                              controller: nameController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: primaryColorApp),
                                ),
                              ),
                            )
                          : Text(
                              product.nombre ?? 'Sin nombre',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                      const SizedBox(height: 3),
                      Text(
                        'Categoría: ${product.categoria ?? 'Sin categoría'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _KpiTile(
                        label: 'Disponible total',
                        value: '${product.cantidadDisponible ?? 0}',
                        unit: product.unidadMedida ?? 'UND',
                        color: Colors.green.shade700,
                        bg: Colors.green.shade50,
                      ),
                      const SizedBox(width: 10),
                      _KpiTile(
                        label: 'Previsto',
                        value: '${product.previsto ?? 0}',
                        unit: product.unidadMedida ?? 'UND',
                        color: primaryColorApp,
                        bg: primaryColorApp.withOpacity(0.06),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AttributeField(
                          label: 'Referencia',
                          value: product.referencia ?? 'N/A',
                          controller: referenceController,
                          editable: isEditMode,
                          numeric: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AttributeField(
                          label: 'Unidad',
                          value: product.unidadMedida ?? 'N/A',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _AttributeField(
                          label: 'Precio',
                          value: product.precio != null ? '\$${product.precio}' : '\$0',
                          controller: priceController,
                          editable: isEditMode,
                          numeric: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AttributeField(
                          label: 'Peso Kg',
                          value: product.peso != null ? '${product.peso} Kg' : '0 Kg',
                          controller: pesoController,
                          editable: isEditMode,
                          numeric: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AttributeField(
                    label: 'Volumen m³',
                    value: product.volumen != null ? '${product.volumen} m³' : '0 m³',
                    controller: volumenController,
                    editable: isEditMode,
                    numeric: true,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded, color: Colors.grey.shade500, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isEditMode
                              ? TextFormField(
                                  controller: barcodeController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    hintText: 'Código de barras',
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CÓDIGO DE BARRAS',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    Text(
                                      product.codigoBarras?.toString() ?? 'Sin código',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        if (!isEditMode)
                          TextButton(
                            onPressed: () => _copyBarcode(context),
                            style: TextButton.styleFrom(
                              backgroundColor: primaryColorApp.withOpacity(0.08),
                              foregroundColor: primaryColorApp,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text(
                              'Copiar',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
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
                          shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            ),
          ],
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded ? 'Ocultar detalles' : 'Mostrar detalles',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bg;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 3),
                Text(unit,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeField extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController? controller;
  final bool editable;
  final bool numeric;

  const _AttributeField({
    required this.label,
    this.value = '',
    this.controller,
    this.editable = false,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: editable ? white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: editable ? primaryColorApp.withOpacity(0.4) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: editable
                ? TextFormField(
                    controller: controller,
                    keyboardType: numeric
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
          ),
        ],
      ),
    );
  }
}
