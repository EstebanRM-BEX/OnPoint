import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class LocationCardButtonCreateMassTransfer extends StatelessWidget {
  final dynamic bloc;
  final bool ubicacionFija;
  final Color cardColor;
  final Color textAndIconColor;
  final Color lockCardColor;
  final String title;
  final String routeName;
  final bool isLocationDest;

  const LocationCardButtonCreateMassTransfer({
    super.key,
    required this.bloc,
    required this.ubicacionFija,
    this.cardColor = Colors.white,
    this.textAndIconColor = Colors.blue,
    this.lockCardColor = Colors.white,
    required this.title,
    required this.routeName,
    required this.isLocationDest,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InfoRapidaBloc, InfoRapidaState>(
      builder: (context, state) {
// --- Lógica de activación de la tarjeta ---
        bool canNavigate = true;

        // La función a ejecutar si la condición es TRUE
        final VoidCallback? onPressed = canNavigate
            ? () {
                Navigator.pushReplacementNamed(
                  context,
                  routeName,
                  arguments: [isLocationDest],
                );
              }
            : null; // Si no puede navegar, el onTap es null

        // --- Fin de Lógica de activación ---

        return Column(
          children: [
            Row(
              children: [
                // Card principal con GestureDetector
                Expanded(
                  child: GestureDetector(
                    onTap: onPressed, // ✅ Aquí pasamos la función VoidCallback?
                    child: Card(
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Row(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textAndIconColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Image.asset(
                              'assets/icons/ubicacion.png',
                              color: textAndIconColor,
                              width: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!context.read<UserBloc>().fabricante.contains("Zebra"))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isLocationDest
                          ? bloc.currentUbicationDest?.name == "" ||
                                  bloc.currentUbicationDest?.name == null
                              ? 'Esperando escaneo'
                              : bloc.currentUbicationDest?.name ?? ""
                          : bloc.currentUbication?.name == "" ||
                                  bloc.currentUbication?.name == null
                              ? 'Esperando escaneo'
                              : bloc.currentUbication?.name ?? "",
                      style: TextStyle(color: black, fontSize: 14),
                    )),
              )
          ],
        );
      },
    );
  }
}
