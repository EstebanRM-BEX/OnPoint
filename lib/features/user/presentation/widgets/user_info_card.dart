import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import '../../domain/entities/user_configuration.dart';
import 'config_card.dart';

/// Perfil del usuario en sesión: avatar, nombre, correo, rol, versión de la
/// app, servidor y acción de comprobar actualizaciones.
class UserInfoCard extends StatefulWidget {
  final UserProfile profile;
  final String versionApp;
  final VoidCallback onCheckUpdates;

  const UserInfoCard({
    super.key,
    required this.profile,
    required this.versionApp,
    required this.onCheckUpdates,
  });

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  // Se lee una sola vez (no en cada rebuild del BlocConsumer de la página).
  late final Future<String> _serverUrl = PrefUtils.getEnterprise();

  String get _initials {
    final parts = (widget.profile.name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return ConfigCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(initials: _initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Correo completo (sin recortar): puede ocupar varias
                    // líneas.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.mail_outline,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.email ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if ((profile.rol ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                _RoleBadge(role: profile.rol!),
              ],
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _InfoTile(
            label: 'VERSIÓN APP',
            child: Text(
              'v${widget.versionApp}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // URL completa, sin recortar: puede ocupar varias líneas.
          _InfoTile(
            label: 'SERVIDOR',
            child: FutureBuilder<String>(
              future: _serverUrl,
              builder: (_, snapshot) => SelectableText(
                snapshot.data ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onCheckUpdates,
            icon: const Icon(Icons.sync, size: 16),
            label: const Text('Comprobar actualizaciones'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF00589A), primaryColorApp, Color(0xFF38BDF8)],
            ),
          ),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColorApp.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColorApp.withOpacity(0.25)),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: primaryColorApp,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ConfigText.caption),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
