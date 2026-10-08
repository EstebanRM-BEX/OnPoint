import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/presentation/utils/info_rapida_format.dart';

/// Tarjeta de una ubicación dentro del detalle de producto: identifica la
/// zona a partir de la ruta de ubicación, muestra sus métricas de stock y
/// permite transferir cuando el producto no está dentro de un paquete.
class LocationCard extends StatelessWidget {
  final UbicacionProducto ubicacion;
  final VoidCallback onTransfer;

  const LocationCard({
    super.key,
    required this.ubicacion,
    required this.onTransfer,
  });

  // Deriva el nombre de la zona a partir de la ruta de ubicación
  // ("CVC/Existencias/50/50-P01" -> "Existencias"). Con menos de 2 segmentos
  // cae a "General".
  String get _zoneName {
    final parts = ubicacion.ubicacion.split('/');
    return parts.length > 1 && parts[1].trim().isNotEmpty
        ? parts[1].trim()
        : 'General';
  }

  bool get _isReturnsZone => _zoneName.toLowerCase().contains('devol');

  bool get _hasStock => ubicacion.cantidadMano > 0;

  String get _unit => ubicacion.unidadMedida ?? 'UND';

  @override
  Widget build(BuildContext context) {
    final zoneColor = _isReturnsZone ? Colors.amber.shade800 : primaryColorApp;
    final zoneIconBg = _isReturnsZone
        ? Colors.amber.shade100
        : primaryColorApp.withOpacity(0.08);
    final zoneIcon = _isReturnsZone
        ? Icons.undo_rounded
        : Icons.warehouse_rounded;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: zoneIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(zoneIcon, size: 13, color: zoneColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zona $_zoneName'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                        color: _isReturnsZone
                            ? zoneColor
                            : Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      orDefault(ubicacion.ubicacion, 'Sin nombre'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColorApp,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _hasStock
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _hasStock ? 'Disponible' : 'Sin stock',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _hasStock
                        ? Colors.green.shade800
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                _MetricCell(
                  label: 'Disponible',
                  value: '${formatCantidad(ubicacion.cantidadMano)} $_unit',
                  valueColor: Colors.green.shade700,
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                _MetricCell(
                  label: 'En inventario',
                  value: '${formatCantidad(ubicacion.cantidad)} $_unit',
                  valueColor: Colors.grey.shade800,
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade200),
                _MetricCell(
                  label: 'Reservado',
                  value: '${formatCantidad(ubicacion.reservado)} $_unit',
                  valueColor: Colors.amber.shade800,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _MetaRow(
            'Propietario:',
            (ubicacion.propietario == null || ubicacion.propietario == '')
                ? 'Sin propietario'
                : ubicacion.propietario!,
          ),
          _MetaRow(
            'Lote:',
            (ubicacion.lote == null || ubicacion.lote == '')
                ? 'Sin lote'
                : ubicacion.lote!,
          ),
          _MetaRow('Fecha de entrada:', '${ubicacion.fechaEntrada}'),
          _MetaRow(
            'Fecha de caducidad:',
            (ubicacion.fechaCaducidad == null || ubicacion.fechaCaducidad == '')
                ? 'Sin fecha de caducidad'
                : ubicacion.fechaCaducidad!,
          ),
          _MetaRow(
            'Paquete:',
            ubicacion.packing == true
                ? '${ubicacion.nombrePaquete}'
                : 'Sin paquete',
            valueColor: ubicacion.packing == true ? Colors.red : null,
          ),
          if (ubicacion.packing == false) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTransfer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColorApp,
                  backgroundColor: primaryColorApp.withOpacity(0.06),
                  side: BorderSide(color: primaryColorApp.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.compare_arrows_rounded, size: 16),
                label: const Text(
                  'TRANSFERIR',
                  style: TextStyle(
                    fontSize: 11,
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
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
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
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
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
