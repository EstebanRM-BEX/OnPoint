import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/features/websocket/presentation/bloc/websocket_bloc.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';

/// Banner que aparece en el header cuando el WebSocket está desconectado o reconectando.
/// Invisible cuando el WS está conectado o en estado inicial.
class _WebSocketStatusBanner extends StatelessWidget {
  const _WebSocketStatusBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebSocketBloc, WebSocketState>(
      buildWhen: (prev, curr) =>
          curr is WebSocketReconnecting ||
          curr is WebSocketDisconnected ||
          curr is WebSocketConnected ||
          (prev is WebSocketReconnecting || prev is WebSocketDisconnected),
      builder: (context, state) {
        if (state is WebSocketReconnecting) {
          return _banner(
            color: Colors.amber.shade700,
            icon: Icons.sync,
            text: 'Reconectando servidor… (intento ${state.attempt})',
          );
        }
        if (state is WebSocketDisconnected) {
          return _banner(
            color: Colors.red.shade700,
            icon: Icons.cloud_off,
            text: 'Servidor desconectado',
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _banner({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      height: 36,
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomHeaderWidget extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback? onCalendar;
  final bool showCalendar;
  final VoidCallback? onFilterPropietario;
  final bool hasActivePropietarioFilter;
  final Widget? popupMenu;

  const CustomHeaderWidget({
    super.key,
    required this.title,
    required this.onBack,
    required this.onRefresh,
    this.onCalendar,
    this.showCalendar = true,
    this.onFilterPropietario,
    this.hasActivePropietarioFilter = false,
    this.popupMenu,
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
              const _WebSocketStatusBanner(),
              Padding(
                padding: EdgeInsets.only(left: 10, right: 10, bottom: 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: white),
                          onPressed: onBack,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onRefresh,
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
                              const Icon(Icons.refresh, color: white, size: 20),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (popupMenu != null) popupMenu!,
                        if (onFilterPropietario != null)
                          IconButton(
                            icon: Icon(
                              Icons.person_search_outlined,
                              color: hasActivePropietarioFilter
                                  ? Colors.amber
                                  : white,
                            ),
                            onPressed: onFilterPropietario,
                          ),
                        if (showCalendar)
                          IconButton(
                            icon: const Icon(
                              Icons.calendar_month,
                              color: white,
                            ),
                            onPressed: onCalendar,
                          )
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
