import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class Background extends StatelessWidget {
  final boxDecoration = const BoxDecoration(
      gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.2, 0.8],
          colors: [white, primaryColorApp]));

  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Purple Gradinet
        Container(decoration: boxDecoration),
        // Pink box
        Positioned(top: -150, left: -10, child: _PinkBox()),
        Positioned(bottom: -200, right: -30, child: _PinkBox2()),
      ],
    );
  }
}

class _PinkBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -pi / 6,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(80),
            gradient: const LinearGradient(colors: [white, primaryColorApp])),
      ),
    );
  }
}

class _PinkBox2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -pi / 6,
      child: Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(80),
            gradient: const LinearGradient(colors: [white, primaryColorApp])),
      ),
    );
  }
}
