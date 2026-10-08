import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Tarjeta principal: visor con esquinas y láser animado, instrucción y
/// entidades que se pueden consultar.
class ScanHeroCard extends StatelessWidget {
  const ScanHeroCard({super.key});

  static const _entities = [
    (Icons.inventory_2_outlined, 'Producto', primaryColorApp),
    (Icons.archive_outlined, 'Paquete', Color(0xFFB45309)),
    (Icons.tag, 'Lote / Serie', Color(0xFF7E22CE)),
    (Icons.location_on_outlined, 'Ubicación', Color(0xFF047857)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          const _Viewfinder(),
          const SizedBox(height: 16),
          const Text(
            'Escanee cualquier etiqueta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text.rich(
            TextSpan(
              text: 'Este es el módulo de información rápida de ',
              children: [
                TextSpan(
                  text: '360 software',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryColorApp,
                  ),
                ),
                TextSpan(text: ' para '),
                TextSpan(
                  text: 'OnPoint',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryColorApp,
                  ),
                ),
                TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          const Text(
            'ENTIDADES COMPATIBLES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.6,
            children: [
              for (final (icon, label, color) in _entities)
                _EntityChip(icon: icon, label: label, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _EntityChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visor de escaneo: esquinas de marca y línea láser que sube y baja.
class _Viewfinder extends StatefulWidget {
  const _Viewfinder();

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laser = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _laser.dispose();
    super.dispose();
  }

  static const double _width = 192;
  static const double _height = 144;

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary: la animación repinta solo el visor, no la pantalla.
    return RepaintBoundary(
      child: Container(
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: _BarcodeGraphic(),
              ),
            ),
            ..._corners(),
            AnimatedBuilder(
              animation: _laser,
              builder: (_, __) => Positioned(
                left: 12,
                right: 12,
                top: 10 + (_height - 22) * _laser.value,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.1),
                        Colors.red,
                        Colors.red.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners() {
    const side = BorderSide(color: primaryColorApp, width: 2.5);
    const size = 18.0;
    const inset = 8.0;
    Widget corner({
      double? top,
      double? left,
      double? right,
      double? bottom,
      required Border border,
    }) => Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(border: border),
      ),
    );
    return [
      corner(
        top: inset,
        left: inset,
        border: const Border(top: side, left: side),
      ),
      corner(
        top: inset,
        right: inset,
        border: const Border(top: side, right: side),
      ),
      corner(
        bottom: inset,
        left: inset,
        border: const Border(bottom: side, left: side),
      ),
      corner(
        bottom: inset,
        right: inset,
        border: const Border(bottom: side, right: side),
      ),
    ];
  }
}

class _BarcodeGraphic extends StatelessWidget {
  const _BarcodeGraphic();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/barcode.svg',
      colorFilter: const ColorFilter.mode(Color(0xFF334155), BlendMode.srcIn),
      fit: BoxFit.contain,
    );
  }
}
