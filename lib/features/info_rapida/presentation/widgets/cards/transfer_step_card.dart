import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Paso del flujo de transferencia: punto de estado a la izquierda y tarjeta
/// con título e icono.
class TransferStepCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final Color dotColor;
  final Color? cardColor;
  final VoidCallback? onTitleTap;
  final List<Widget> children;

  const TransferStepCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.dotColor = green,
    this.cardColor,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: primaryColorApp),
        ),
        const Spacer(),
        icon,
      ],
    );

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: Card(
            color: cardColor ?? Colors.green[100],
            elevation: 5,
            margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onTitleTap != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTitleTap,
                      child: header,
                    )
                  else
                    header,
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Icono SVG de los pasos de transferencia.
class TransferStepSvgIcon extends StatelessWidget {
  final String asset;

  const TransferStepSvgIcon(this.asset, {super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      height: 20,
      width: 20,
      colorFilter: const ColorFilter.mode(primaryColorApp, BlendMode.srcIn),
    );
  }
}

/// Icono PNG de los pasos de transferencia.
class TransferStepPngIcon extends StatelessWidget {
  final String asset;

  const TransferStepPngIcon(this.asset, {super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, color: primaryColorApp, width: 20);
  }
}
