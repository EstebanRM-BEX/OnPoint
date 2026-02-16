import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/views/inventario/screens/bloc/inventario_bloc.dart';

class LocationCardButton extends StatelessWidget {
  final dynamic bloc;
  final bool ubicacionFija;
  final Color cardColor;
  final Color textAndIconColor;
  final Color lockCardColor;
  final String title;
  final String iconPath;
  final String dialogTitle;
  final String dialogMessage;
  final String routeName;

  const LocationCardButton({
    super.key,
    required this.bloc,
    required this.ubicacionFija,
    this.cardColor = Colors.white,
    this.textAndIconColor = Colors.blue,
    this.lockCardColor = Colors.white,
    this.title = 'Ubicación de existencias',
    this.iconPath = "assets/icons/ubicacion.png",
    this.dialogTitle = '360 Software Informa',
    this.dialogMessage = "No hay ubicaciones cargadas, por favor cargues las ubicaciones",
    this.routeName = 'search-location',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Card principal con GestureDetector
        Expanded(
          child: GestureDetector(
            onTap: !bloc.locationIsOk && !bloc.productIsOk && !bloc.quantityIsOk
                ? () {
                    if (bloc.ubicacionesFilters.isEmpty) {
                      Get.defaultDialog(
                        title: dialogTitle,
                        titleStyle: TextStyle(
                            color: Colors.red, fontSize: 18),
                        middleText: dialogMessage,
                        middleTextStyle: TextStyle(
                            color: Colors.black, fontSize: 14),
                        backgroundColor: Colors.white,
                        radius: 10,
                      );
                    } else {
                      Navigator.pushReplacementNamed(
                        context,
                        routeName,
                      );
                    }
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
                      iconPath,
                      color: textAndIconColor,
                      width: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Card del candado con su propio GestureDetector
        GestureDetector(
          onTap: (){
            bloc.add(SetUbicacionFijaEvent(!bloc.ubicacionFija));
          }, // Callback para manejar el tap del candado
          child: Card(
            color: lockCardColor,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                bloc.ubicacionFija ? Icons.lock : Icons.lock_open,
                color: bloc.ubicacionFija ? primaryColorApp : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}