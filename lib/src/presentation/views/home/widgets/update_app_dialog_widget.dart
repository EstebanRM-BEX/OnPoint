// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/home/bloc/home_bloc.dart';
import 'package:wms_app/src/services/preferences.dart';

class UpdateAppDialog extends StatefulWidget {
  const UpdateAppDialog({
    super.key,
  });

  @override
  _UpdateAppDialogState createState() => _UpdateAppDialogState();
}

class _UpdateAppDialogState extends State<UpdateAppDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0; // Para saber en qué página estamos

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return AlertDialog(
          // actionsAlignment: MainAxisAlignment.center,
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              'Nueva Actualización Disponible ${context.read<HomeBloc>().appVersion.result?.result?.version ?? ''}',
              style: TextStyle(color: primaryColorApp, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite, // Ajustamos el ancho del dialogo
            height: 300,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Primera página: Novedades de la actualización
                _buildNewFeaturesPage(),
                // Segunda página: Instrucciones para actualizar
                _buildInstructionsPage(),
              ],
            ),
          ),
          actions: [
            if (_currentPage == 1) ...[
              // Solo mostramos los botones cuando estamos en la página de instrucciones
              Center(
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: grey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size(200, 40),
                    ),
                    child: Text(
                      "Recordar Más Tarde",
                      style: TextStyle(color: white, fontSize: 14),
                    )),
              ),

              Center(
                child: ElevatedButton(
                    onPressed: () async {
                      print(context
                          .read<HomeBloc>()
                          .appVersion
                          .result
                          ?.result
                          ?.urlDownload);

                      //abrimos el navegador con la url de descarga
                      await launch(context
                              .read<HomeBloc>()
                              .appVersion
                              .result
                              ?.result
                              ?.urlDownload ??
                          '');

                      //cerramos el dialogo

                      context.read<HomeBloc>().add(ClearDataEvent());
                      PrefUtils.clearPrefs();
                      Preferences.removeUrlWebsite();
                      await DataBaseSqlite().deleteBDCloseSession();
                      await Future.delayed(const Duration(seconds: 1));
                      PrefUtils.setIsLoggedIn(false);

                      // Cerrar el diálogo de carga
                      Navigator.pop(context);

                      // Navegar a la pantalla de inicio
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        'enterprice',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size(200, 40),
                    ),
                    child: Text(
                      "Actualizar",
                      style: TextStyle(color: white, fontSize: 14),
                    )),
              ),
            ],
          ],
        );
      },
    );
  }

  // Función para mostrar las novedades
  Widget _buildNewFeaturesPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ListView.builder(
           physics: const AlwaysScrollableScrollPhysics(),
            itemCount: context
                    .read<HomeBloc>()
                    .appVersion
                    .result
                    ?.result
                    ?.notes
                    ?.length ??
                0,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                color: white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '✅ ${context.read<HomeBloc>().appVersion.result?.result?.notes?[index]}',
                    textAlign: TextAlign.justify,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Siguiente",
                style: TextStyle(color: white, fontSize: 14),
              )),
        )
      ],
    );
  }

  String _formatDate(String? releaseDate) {
    if (releaseDate == null) return '';

    // Si la fecha está en formato String, convertirla a DateTime
    DateTime dateTime = DateTime.parse(releaseDate);

    // Usar DateFormat para formatear la fecha
    String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);

    return formattedDate;
  }

  // Función para mostrar las instrucciones para la actualización
  Widget _buildInstructionsPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Instrucciones para actualizar:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          "Para actualizar la aplicación,\npresiona el botón de actualizar y descarga la nueva versión de la aplicación. Una vez presionado el botón de actualizar, cerrará la aplicación en su sesión iniciada e iniciará la descarga (Instalador de paquetes o el navegador).\nInstale la app e ingrese de nuevo.",
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
