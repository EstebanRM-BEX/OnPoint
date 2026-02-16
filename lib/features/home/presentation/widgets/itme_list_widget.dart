import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class ItemList extends StatelessWidget {
  const ItemList({
    super.key,
    required this.size,
    required this.color,
    required this.title,
    required this.value,
    required this.urlImg,
  });

  final Size size;
  final Color color;
  final String title;
  final String value;
  final String urlImg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width * 0.6,
      child: Card(
        color: white,
        elevation: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/$urlImg",
              fit: BoxFit.cover,
              width: 20,
              color: primaryColorApp,
            ),
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(value,
                style: TextStyle(
                    color: primaryColorApp,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}
