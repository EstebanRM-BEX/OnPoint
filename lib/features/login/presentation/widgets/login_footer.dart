import 'package:flutter/material.dart';

/// Pie del login: servidor al que se conecta la terminal y créditos.
class LoginFooter extends StatelessWidget {
  final String serverUrl;

  const LoginFooter({super.key, required this.serverUrl});

  String get _host {
    final uri = Uri.tryParse(serverUrl);
    return (uri != null && uri.host.isNotEmpty) ? uri.host : serverUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (serverUrl.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: 'Servidor: ',
                      children: [
                        TextSpan(
                          text: _host,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF022C22),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'OnPoint Logistics Suite • 360 Software S.A.S',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
