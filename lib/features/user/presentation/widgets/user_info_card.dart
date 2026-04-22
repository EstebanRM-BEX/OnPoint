import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import '../../domain/entities/user_configuration.dart';

class UserInfoCard extends StatelessWidget {
  final UserProfile profile;
  final String versionApp;

  const UserInfoCard({
    super.key,
    required this.profile,
    required this.versionApp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildInfoRow("Nombre: ", profile.name ?? ''),
            const SizedBox(height: 5),
            _buildInfoRow("Correo: ", profile.email ?? ''),
            const SizedBox(height: 5),
            _buildInfoRow("Rol: ", profile.rol ?? ''),
            const SizedBox(height: 5),
            _buildInfoRow("Version App: ", versionApp),
            const SizedBox(height: 5),
            FutureBuilder<String>(
              future: PrefUtils.getEnterprise(),
              builder: (context, snapshot) {
                final enterprise = snapshot.data ?? 'Cargando...';
                return _buildInfoRow("Url: ", enterprise);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
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
    );
  }
}
