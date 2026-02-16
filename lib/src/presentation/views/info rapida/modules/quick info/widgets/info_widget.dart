import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

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

class EditableReferenceRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Visibility(
      visible: isExpanded,
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
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColorApp,
                ),
              ),
            ),

            // Campo editable
            SizedBox(
              width: size.width * 0.6,
              height: isName ? 40 : 25,
              child: TextFormField(
                //tipo de campo
                keyboardType:
                    isNumber ? TextInputType.number : TextInputType.text,
                controller: controller,
                // initialValue:
                //     controller == null ? (reference ?? 'Sin referencia') : null,
                maxLines: isName ? 2 : 1,
                readOnly: !isEditMode,
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
                  fillColor: isEditMode ? Colors.white : Colors.transparent,
                ),
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputBorder? _getBorder() {
    return isEditMode
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
