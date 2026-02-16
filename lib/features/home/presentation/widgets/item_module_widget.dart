import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';

class ImteModule extends StatelessWidget {
  final String urlImg;
  final String title;

  const ImteModule({
    super.key,
    required this.urlImg,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(215, 255, 255, 255),
      elevation: 5,
      child: SizedBox(
        width: 100,
        height: 100,
        child: _ImteModuleContent(
          urlImg: urlImg,
          title: title,
        ),
      ),
    );
  }
}

class _ImteModuleContent extends StatelessWidget {
  final String urlImg;
  final String title;

  const _ImteModuleContent({
    required this.urlImg,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: SvgPicture.asset(
                "assets/icons/$urlImg",
                color: Colors.black,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: primaryColorApp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
