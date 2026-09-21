import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import '../../domain/entities/device_info.dart';
import 'config_card.dart';

/// Datos técnicos de la PDA.
class DeviceInfoCard extends StatelessWidget {
  final DeviceInfo deviceInfo;

  const DeviceInfoCard({super.key, required this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool)>[
      ('Modelo', deviceInfo.model, true),
      (
        'Versión OS / Fabricante',
        'Android ${deviceInfo.version} • ${deviceInfo.manufacturer}',
        false,
      ),
      ('MAC Address', deviceInfo.mac, true),
      ('IMEI Terminal', deviceInfo.imei, true),
    ];

    return ConfigCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: primaryColorApp.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.smartphone,
                  size: 16,
                  color: primaryColorApp,
                ),
              ),
              const SizedBox(width: 8),
              const Text('INFORMACIÓN PDA', style: ConfigText.sectionTitle),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            _InfoRow(label: rows[i].$1, value: rows[i].$2, mono: rows[i].$3),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.mono,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: ConfigText.label),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono
                  ? ConfigText.value.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    )
                  : ConfigText.value,
            ),
          ),
        ],
      ),
    );
  }
}
