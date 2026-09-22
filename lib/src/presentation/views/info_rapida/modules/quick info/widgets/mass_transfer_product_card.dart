import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/info_rapida/models/info_rapida_model.dart';

/// Tarjeta de un producto dentro de una ubicación. Fuera de modo
/// transferencia masiva, un tap navega al detalle del producto; en modo
/// transferencia masiva, selecciona/deselecciona (deshabilitado si el
/// producto está en un paquete o sin cantidad disponible).
class MassTransferProductCard extends StatelessWidget {
  final Producto producto;
  final bool massTransferActive;
  final bool isSelected;
  final ValueChanged<bool> onToggleSelected;
  final VoidCallback onOpenDetail;

  const MassTransferProductCard({
    super.key,
    required this.producto,
    required this.massTransferActive,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onOpenDetail,
  });

  bool get _selectable =>
      producto.packing != true && (producto.cantidadMano ?? 0) > 0;

  bool get _tieneManejoPropietario =>
      producto.manejoPropietario == true || producto.manejoPropietario == 1;

  String get _unit => producto.unidadMedida ?? 'UND';

  @override
  Widget build(BuildContext context) {
    final highlighted = massTransferActive && isSelected;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: massTransferActive
          ? (_selectable ? () => onToggleSelected(!isSelected) : null)
          : onOpenDetail,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlighted ? primaryColorApp.withOpacity(0.04) : white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlighted
                ? primaryColorApp.withOpacity(0.5)
                : Colors.grey.shade200,
            width: highlighted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (massTransferActive)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4),
                child: Checkbox(
                  value: isSelected,
                  onChanged: _selectable
                      ? (value) => onToggleSelected(value ?? false)
                      : null,
                  activeColor: primaryColorApp,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.producto ?? 'Sin nombre',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryColorApp,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _MetricCell(
                              label: 'Disponible',
                              value: '${producto.cantidadMano ?? 0} $_unit',
                              valueColor: Colors.green.shade700,
                            ),
                            _MetricCell(
                              label: 'En inventario',
                              value: '${producto.cantidad ?? 0} $_unit',
                              valueColor: Colors.grey.shade800,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cantidad reservada:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              '${producto.reservado ?? 0} $_unit',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MetaRow(
                    'Barcode:',
                    producto.codigoBarras == null ||
                            producto.codigoBarras == false
                        ? 'Sin barcode'
                        : '${producto.codigoBarras}',
                  ),
                  _MetaRow(
                    'Lote:',
                    (producto.lote == null || producto.lote == '')
                        ? 'Sin lote'
                        : producto.lote!,
                    valueColor: (producto.lote == null || producto.lote == '')
                        ? Colors.red
                        : null,
                  ),
                  _MetaRow(
                    'Caducidad:',
                    (producto.fechaVencimiento == null ||
                            producto.fechaVencimiento == '')
                        ? 'Sin caducidad'
                        : producto.fechaVencimiento!,
                    valueColor:
                        (producto.fechaVencimiento == null ||
                            producto.fechaVencimiento == '')
                        ? Colors.red
                        : null,
                  ),
                  _MetaRow(
                    'Paquete:',
                    producto.packing == true
                        ? '${producto.nombrePaquete}'
                        : 'Sin paquete',
                    valueColor: producto.packing == true ? null : Colors.red,
                  ),
                  if (_tieneManejoPropietario)
                    _MetaRow('Propietario:', '${producto.propietario}'),
                ],
              ),
            ),
            if (!massTransferActive)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade300,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
