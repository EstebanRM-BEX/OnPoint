// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

// Definición de las funciones de callback
typedef SearchCallback = void Function(String value);
typedef ClearCallback = void Function();

class DynamicSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final SearchCallback onSearchChanged;
  final ClearCallback onSearchCleared;
  final VoidCallback? onTap;
  final String hintText;
  final double width;

  // Si la lógica de tu BLoC necesita un índice para saber qué lista filtrar (controller.index)
  final dynamic filterIndex;

  const DynamicSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onSearchCleared,
    this.onTap,
    this.hintText = "Buscar...",
    this.filterIndex,
    this.width = double.infinity,
  });

  @override
  _DynamicSearchBarState createState() => _DynamicSearchBarState();
}

class _DynamicSearchBarState extends State<DynamicSearchBar> {
  // Lógica para manejar la limpieza y enfoque
  void _handleClear() {
    widget.controller.clear();
    widget.onSearchCleared();
  }

  @override
  Widget build(BuildContext context) {
    // La lógica de Zebra se maneja aquí (asumiendo que UserBloc está disponible globalmente)

    return Container(
      height: 55,
      width: widget.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 3,
                child: TextFormField(
                  showCursor: true,
                  textAlignVertical: TextAlignVertical.center,
                  controller: widget.controller,

                  // 💥 onChanged: Llama al callback de búsqueda
                  onChanged: (value) {
                    widget.onSearchChanged(value);
                  },

                  // 💥 onTap: Activa el teclado para Zebra si está desactivado
                  onTap: context
                          .select((UserBloc bloc) => bloc.fabricante)
                          .contains("Zebra")
                      ? widget.onTap
                      : null, // ✅ Se usa la propiedad

                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: grey),
                    suffixIcon: IconButton(
                      onPressed: _handleClear, // Llama a la función de limpieza
                      icon: const Icon(Icons.close, color: grey),
                    ),
                    disabledBorder: const OutlineInputBorder(),
                    hintText: widget.hintText,
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
