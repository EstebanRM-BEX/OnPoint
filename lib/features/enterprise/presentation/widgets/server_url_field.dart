import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/validator_utils.dart';
import 'package:wms_app/shared/widgets/auth/auth_field_icon.dart';

/// Campo de dirección del servidor con etiqueta y badge SSL (solo si la URL
/// escrita empieza por https://).
class ServerUrlField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const ServerUrlField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Expanded(child: _SectionLabel('Dirección del servidor')),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, __) =>
                    value.text.trim().toLowerCase().startsWith('https://')
                    ? const _SslBadge()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autocorrect: false,
          keyboardType: TextInputType.url,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          onTap: () {
            // Cubre el caso donde el campo ya tenía foco pero el IME del
            // PDA cerró el teclado (Chainway/Android 13 y similares).
            SystemChannels.textInput.invokeMethod('TextInput.show');
          },
          decoration: InputDecoration(
            hintText: 'https://su-empresa.360software.com',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            prefixIcon: const AuthFieldIcon(Icons.language),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: IconButton(
              onPressed: controller.clear,
              icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
            ),
            enabledBorder: _border(primaryColorApp.withOpacity(0.25)),
            focusedBorder: _border(primaryColorApp),
            errorBorder: _border(red),
            focusedErrorBorder: _border(red),
          ),
          validator: (value) => Validator.isEmpty(value, context),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: 2),
  );
}

class _SslBadge extends StatelessWidget {
  const _SslBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1FAE5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 12, color: Color(0xFF10B981)),
          SizedBox(width: 4),
          Text(
            'SSL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Color(0xFF64748B),
      ),
    );
  }
}
