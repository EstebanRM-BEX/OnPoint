import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';

// Widget reutilizable para mostrar las filas con título y valor
class ProductInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const ProductInfoRow({
    super.key,
    required this.title,
    required this.value,
    this.color = black,
  });

  @override
  Widget build(BuildContext context) {
   return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.isNotEmpty ? '$title ' : '', // Solo muestra espacio si hay título
          style: TextStyle(fontSize: 12, color: primaryColorApp),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: color),
          maxLines: 2, 
          overflow: TextOverflow.ellipsis, 
        ),
      ],
    );
  }
}

class EditableReferenceRow extends StatefulWidget {
  final String title;
  final bool isEditMode;
  final void Function()? onTap;
  final TextEditingController? controller;
  final bool isName;
  final bool isNumber;
  final bool isExpanded;

  const EditableReferenceRow({
    super.key,
    required this.title,
    required this.isEditMode,
    this.onTap,
    this.controller,
    this.isName = false,
    this.isNumber = false,
    required this.isExpanded,
  });

  @override
  State<EditableReferenceRow> createState() => _EditableReferenceRowState();
}

class _EditableReferenceRowState extends State<EditableReferenceRow>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  // Watchdog: reabre el teclado si el IME del PDA (Zebra/Urovo/Chainway) lo
  // cierra solo mientras el campo conserva el foco.
  late final KeyboardWatchdog _kbWatchdog =
      KeyboardWatchdog(state: this, focusNode: _focusNode);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _kbWatchdog.onMetricsChanged();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kbWatchdog.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Visibility(
      visible: widget.isExpanded,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 1,
        ),
        child: Row(
          children: [
            // Label
            Container(
              width: size.width * 0.25,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColorApp,
                ),
              ),
            ),

            // Campo editable
            SizedBox(
              width: size.width * 0.6,
              height: widget.isName ? 40 : 25,
              child: TextFormField(
                //tipo de campo
                keyboardType: widget.isNumber
                    ? TextInputType.number
                    : TextInputType.text,
                controller: widget.controller,
                focusNode: _focusNode,
                // initialValue:
                //     controller == null ? (reference ?? 'Sin referencia') : null,
                maxLines: widget.isName ? 2 : 1,
                readOnly: !widget.isEditMode,
                style: TextStyle(
                  fontSize: 12,
                  color: black,
                  height: 1.0,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 10,
                  ),
                  border: _getBorder(),
                  enabledBorder: _getBorder(),
                  focusedBorder: _getBorder(),
                  filled: true,
                  fillColor:
                      widget.isEditMode ? Colors.white : Colors.transparent,
                ),
                onTap: widget.onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputBorder? _getBorder() {
    return widget.isEditMode
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(
              color: primaryColorApp,
              width: 1.0,
            ),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1.0,
            ),
          );
  }
}
