import 'package:flutter/material.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import '../../domain/entities/device_info.dart';

class DeviceInfoCard extends StatelessWidget {
  final DeviceInfo deviceInfo;

  const DeviceInfoCard({super.key, required this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Center(
              child: Text("Informacion PDA:",
                  style: TextStyle(fontSize: 14, color: primaryColorApp)),
            ),
            const SizedBox(height: 10),
            _buildInfoRow("Modelo: ", deviceInfo.model),
            _buildInfoRow("Version: ", deviceInfo.version),
            _buildInfoRow("Fabricante: ", deviceInfo.manufacturer),
            _buildInfoRow("Mac: ", deviceInfo.mac),
            _buildInfoRow("IMEI: ", deviceInfo.imei),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: primaryColorApp)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
