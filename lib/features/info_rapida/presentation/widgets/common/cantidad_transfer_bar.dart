import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Barra inferior de la transferencia individual: disponible, campo de
/// cantidad y botón "APLICAR CANTIDAD".
class CantidadTransferBar extends StatelessWidget {
  final String disponible;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onApply;

  const CantidadTransferBar({
    super.key,
    required this.disponible,
    required this.controller,
    required this.focusNode,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              color: white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Text(
                      'Disponible:',
                      style: TextStyle(color: black, fontSize: 13),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        '($disponible)',
                        style: const TextStyle(
                          color: primaryColorApp,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ListenableBuilder(
                          listenable: focusNode,
                          builder: (context, _) => TextFormField(
                            focusNode: focusNode,
                            controller: controller,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            showCursor: false,
                            style: const TextStyle(color: black, fontSize: 15),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                onPressed: () => focusNode.hasFocus
                                    ? focusNode.unfocus()
                                    : focusNode.requestFocus(),
                                icon: Icon(
                                  focusNode.hasFocus ? Icons.close : Icons.edit,
                                  size: 20,
                                  color: primaryColorApp,
                                ),
                              ),
                              hintText: '0',
                              hintStyle: const TextStyle(
                                color: black,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'APLICAR CANTIDAD',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
