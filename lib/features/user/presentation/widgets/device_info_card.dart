import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import '../../domain/entities/device_info.dart';
import 'config_card.dart';

/// Datos técnicos de la PDA.
class DeviceInfoCard extends StatelessWidget {
  final DeviceInfo deviceInfo;

  const DeviceInfoCard({super.key, required this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool, bool)>[
      ('Modelo', deviceInfo.model, true, false),
      (
        'Versión OS / Fabricante',
        'Android ${deviceInfo.version} • ${deviceInfo.manufacturer}',
        false,
        false,
      ),
      ('MAC Address', deviceInfo.mac, true, false),
      ('IMEI Terminal', deviceInfo.imei, true, true),
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
            _InfoRow(
              label: rows[i].$1,
              value: rows[i].$2,
              mono: rows[i].$3,
              copyable: rows[i].$4,
            ),
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
  final bool copyable;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.mono,
    this.copyable = false,
  });

  void _copy(BuildContext context) {
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
    final valueText = Text(
      value,
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: mono
          ? ConfigText.value.copyWith(fontFamily: 'monospace', fontSize: 11)
          : ConfigText.value,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: ConfigText.label),
          const SizedBox(width: 12),
          Expanded(child: valueText),
          if (copyable) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _copy(context),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
