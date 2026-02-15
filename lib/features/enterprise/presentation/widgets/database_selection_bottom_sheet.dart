import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slide_to_act/slide_to_act.dart';
import '../../../../src/core/constans/colors.dart';
import '../bloc/enterprise_bloc.dart';
import '../bloc/enterprise_event.dart';

class DatabaseSelectionBottomSheet extends StatelessWidget {
  final List<String> databases;
  final String url;

  const DatabaseSelectionBottomSheet({
    super.key,
    required this.databases,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(80),
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: databases.length,
          itemBuilder: (context, index) {
            final db = databases[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: SlideAction(
                onSubmit: () {
                  context.read<EnterpriseBloc>().add(
                        SelectDatabaseEvent(database: db, url: url),
                      );
                  Navigator.of(context).pop();
                  return null;
                },
                text: db,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                elevation: 0,
                sliderRotate: false,
                borderRadius: 20,
                sliderButtonIcon: Icon(
                  Icons.lock_open,
                  size: 18,
                  color: primaryColorApp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
