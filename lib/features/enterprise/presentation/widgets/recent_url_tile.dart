import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import '../../domain/entities/recent_url.dart';

/// Tarjeta de una conexión reciente: protocolo, host y fecha de último acceso.
class RecentUrlTile extends StatelessWidget {
  final RecentUrl item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RecentUrlTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(item.url);
    final hasScheme = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    final scheme = hasScheme ? '${uri.scheme}://' : '';
    final host = hasScheme
        ? item.url.substring(item.url.indexOf('://') + 3)
        : item.url;
    final isTest =
        host.toLowerCase().contains('prueba') ||
        host.toLowerCase().contains('test');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryColorApp.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history, color: primaryColorApp, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (scheme.isNotEmpty || isTest)
                      Row(
                        children: [
                          Text(
                            scheme.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          if (isTest) ...[
                            const SizedBox(width: 6),
                            const _TestBadge(),
                          ],
                        ],
                      ),
                    Text(
                      host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Último acceso: ${item.fecha.toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestBadge extends StatelessWidget {
  const _TestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        'TEST',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB45309),
        ),
      ),
    );
  }
}
