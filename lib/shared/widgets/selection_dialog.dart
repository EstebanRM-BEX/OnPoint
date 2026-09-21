import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Opción de un [SelectionDialog].
class SelectionOption {
  final String title;
  final String description;
  final IconData icon;
  final String? tag;
  final VoidCallback onTap;

  const SelectionOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.tag,
  });
}

/// Diálogo modal de OnPoint (diseño "Modal Selección de Picking"): fondo
/// desenfocado, icono de cabecera, título, descripción, contenido y botón
/// inferior. Base de todos los diálogos de selección/aviso del home.
class OnPointModal extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? child;
  final String footerLabel;
  final IconData? footerIcon;
  final bool footerPrimary;
  final VoidCallback? onFooter;

  /// Colores del icono de cabecera (por defecto, los de marca).
  final List<Color>? iconGradient;

  const OnPointModal({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.child,
    this.footerLabel = 'Cancelar',
    this.footerIcon = Icons.arrow_back,
    this.footerPrimary = false,
    this.onFooter,
    this.iconGradient,
  });

  @override
  Widget build(BuildContext context) {
    final close = onFooter ?? () => Navigator.pop(context);
    final gradient = iconGradient ?? const [primaryColorApp, Color(0xFF38BDF8)];

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _HeaderIcon(icon: icon, colors: gradient),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (child != null) ...[const SizedBox(height: 20), child!],
                    const SizedBox(height: 20),
                    _FooterButton(
                      label: footerLabel,
                      icon: footerIcon,
                      primary: footerPrimary,
                      onPressed: close,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _CloseButton(onPressed: () => Navigator.pop(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo de selección: [OnPointModal] con una lista de [SelectionOption].
class SelectionDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<SelectionOption> options;

  const SelectionDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return OnPointModal(
      icon: icon,
      title: title,
      message: message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in options) ...[
            _OptionTile(option: option),
            if (option != options.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  const _HeaderIcon({required this.icon, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.first.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 32,
          child: Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final SelectionOption option;
  const _OptionTile({required this.option});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: option.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColorApp.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColorApp.withOpacity(0.15)),
                ),
                child: Icon(option.icon, size: 22, color: primaryColorApp),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          option.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (option.tag != null) _Tag(option.tag!),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool primary;
  final VoidCallback onPressed;

  const _FooterButton({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(label.toUpperCase()),
        style: FilledButton.styleFrom(
          backgroundColor: primary ? primaryColorApp : const Color(0xFFF1F5F9),
          foregroundColor: primary ? Colors.white : const Color(0xFF64748B),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
