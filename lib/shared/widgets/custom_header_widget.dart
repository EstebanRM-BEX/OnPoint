import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

class CustomHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onCalendar;
  final bool showCalendar;

  const CustomHeaderWidget({
    super.key,
    required this.title,
    required this.onBack,
    required this.onRefresh,
    this.onCalendar,
    this.showCalendar = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Container(
      decoration: BoxDecoration(
        color: primaryColorApp,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
        builder: (context, status) {
          return Column(
            children: [
              const WarningWidgetCubit(),
              Padding(
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: status != ConnectionStatus.online ? 0 : 25,
                  bottom: 0,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: white),
                          onPressed: onBack,
                        ),
                        GestureDetector(
                          onTap: onRefresh,
                          child: Padding(
                            padding: EdgeInsets.only(left: size.width * 0.2),
                            child: Row(
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.refresh,
                                  color: white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (showCalendar)
                          IconButton(
                            icon:
                                const Icon(Icons.calendar_month, color: white),
                            onPressed: onCalendar,
                          )
                        else
                          const SizedBox(width: 48), // Match IconButton width
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
