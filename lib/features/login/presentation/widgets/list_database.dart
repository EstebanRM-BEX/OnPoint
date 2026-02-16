import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';

class DetailClientSale extends StatefulWidget {
  final List<String> listDB; // Asegúrate de que listDB es una lista de Strings
  const DetailClientSale({super.key, required this.listDB});

  @override
  State<DetailClientSale> createState() => _DetailClientSaleState();
}

class _DetailClientSaleState extends State<DetailClientSale> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(80),
          ),
        ),
        child: ListView.builder(
          itemCount: widget.listDB.length,
          itemBuilder: (context, index) {
            final element = widget.listDB[index];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 6.0), // Similar a gapH12
              child: SlideAction(
                onSubmit: () {
                  Navigator.of(context).pop();
                  getIt<IStorageService>().nameDatabase = element;
                  Navigator.pushReplacementNamed(context, 'auth');

                  return null;
                },
                text: element,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                elevation: 0,
                sliderRotate: false,
                borderRadius: 20,
                sliderButtonIcon: Icon(
                  Icons.lock_open,
                  size: 18,
                  color: primaryColorApp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
