import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class LocationCardButtonConteo extends StatelessWidget {
  final dynamic bloc;
  final bool ubicacionFija;
  final Color cardColor;
  final Color textAndIconColor;
  final Color lockCardColor;
  final String title;
  final String routeName;

  const LocationCardButtonConteo({
    super.key,
    required this.bloc,
    required this.ubicacionFija,
    this.cardColor = Colors.white,
    this.textAndIconColor = Colors.blue,
    this.lockCardColor = Colors.white,
    required this.title,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Card principal con GestureDetector
            Expanded(
              child: GestureDetector(
                onTap: !bloc.locationIsOk &&
                        !bloc.productIsOk &&
                        !bloc.quantityIsOk
                    ? () {
                        Navigator.pushReplacementNamed(
                          context,
                          routeName,
                        );
                      }
                    : null,
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
                  bloc.currentUbication?.name == "" ||
                          bloc.currentUbication?.name == null
                      ? 'Esperando escaneo'
                      : bloc.currentUbication?.name ?? "",
                  style: TextStyle(color: black, fontSize: 14),
                )),
          )
      ],
    );
  }
}
