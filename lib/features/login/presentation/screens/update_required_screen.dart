// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';

class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  bool _isLoading = false;

  Future<void> _onUpdate(String urlDownload) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    bool launched = false;
    try {
      launched = await launch(urlDownload);
    } catch (_) {
      launched = false;
    }

    if (!launched) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace de descarga. Intenta nuevamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // URL abierta correctamente → cerrar sesión
    PrefUtils.clearPrefs();
    getIt<IStorageService>().removeUrlWebsite();
    await DataBaseSqlite().deleteBDCloseSession();
    await Future.delayed(const Duration(seconds: 1));
    PrefUtils.setIsLoggedIn(false);

    if (!mounted) return;
    context.read<HomeBloc>().add(ClearDataEvent());
    Navigator.pushNamedAndRemoveUntil(context, 'enterprice', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();
    final versionResult = homeBloc.appVersion.result?.result;
    final serverVersion = versionResult?.version ?? '';
    final notes = versionResult?.notes ?? [];
    final urlDownload = versionResult?.urlDownload ?? '';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        // Botón fijo en la parte inferior — nunca se desborda
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ElevatedButton(
              onPressed: urlDownload.isNotEmpty && !_isLoading
                  ? () => _onUpdate(urlDownload)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Actualizar OnPoint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header con degradado e icono ──────────────────────────
            _Header(serverVersion: serverVersion),

            // ── Cuerpo blanco con título y notas ─────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título y subtítulo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        const Text(
                          '¡Nueva versión disponible!',
                          style: TextStyle(
                            color: primaryColorApp,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Descárgala para poder seguir usando OnPoint',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Notas de la actualización
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.new_releases,
                              size: 16, color: primaryColorApp),
                          const SizedBox(width: 6),
                          Text(
                            'Novedades de esta versión',
                            style: TextStyle(
                              color: primaryColorApp,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF4FB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryColorAppLigth.withOpacity(0.4),
                            ),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(14),
                            itemCount: notes.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 12,
                              color: primaryColorAppLigth.withOpacity(0.4),
                            ),
                            itemBuilder: (_, i) => Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 15,
                                    color: primaryColorApp,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notes[i],
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String serverVersion;
  const _Header({required this.serverVersion});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColorApp, primaryColorAppLigth],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              // Icono con sombra sobre fondo blanco circular
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SvgPicture.asset('assets/images/icono.svg', width: 130, height: 130, fit: BoxFit.cover,),
              ),
              if (serverVersion.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v$serverVersion',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
