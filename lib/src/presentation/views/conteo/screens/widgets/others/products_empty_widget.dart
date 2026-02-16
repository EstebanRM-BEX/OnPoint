import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';

class ProductEmpty extends StatelessWidget {
  const ProductEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: size.height * 0.3),
          const Text('No hay productos',
              style: TextStyle(fontSize: 14, color: grey)),
          const Text('Intente buscar otro producto',
              style: TextStyle(fontSize: 12, color: grey)),
          if (context.read<UserBloc>().fabricante.contains("Zebra"))
            const SizedBox(height: 60),
        ],
      ),
    );
  }
}
