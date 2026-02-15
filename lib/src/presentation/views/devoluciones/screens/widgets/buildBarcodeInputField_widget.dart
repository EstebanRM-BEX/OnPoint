
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class BuildBarcodeInputField extends StatelessWidget {
  final DevolucionesBloc devolucionesBloc;
  final FocusNode focusNode;
  final Function(String) functionValidate;
  final TextEditingController controller;
  final Function(String keyLabel)? functionUpdate;

  const BuildBarcodeInputField({
    super.key,
    required this.devolucionesBloc,
    required this.focusNode,
    required this.functionValidate,
    required this.controller,
    required this.functionUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 0,
        child: context.read<UserBloc>().fabricante.contains('Zebra')
            ? TextFormField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                showCursor: false,
                onChanged: (value) {
                  functionValidate(value);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              )
            : Focus(
                focusNode: focusNode,
                autofocus: true,
                onKey: (node, event) {
                  if (event is RawKeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.enter) {
                      functionValidate(devolucionesBloc.scannedValue1);
                      return KeyEventResult.handled;
                    } else {
                      if (functionUpdate != null) {
                        functionUpdate!(event.data.keyLabel);
                      }
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: const SizedBox(),
              ));
  }
}
