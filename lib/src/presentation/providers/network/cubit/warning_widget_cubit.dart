import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';

class WarningWidgetCubit extends StatelessWidget {
  const WarningWidgetCubit({super.key, this.isTop = true});

  final bool isTop;

  static const _background = Color(0xFF2B2F36);
  static const _accent = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, status) {
        final offline = status != ConnectionStatus.online;
        // Entra y sale deslizándose en vez de aparecer de golpe.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: isTop ? -1 : 1,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: offline
              ? _OfflineBanner(isTop: isTop)
              : const SizedBox(key: ValueKey('online'), width: double.infinity),
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.isTop});

  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('offline'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: WarningWidgetCubit._background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: Offset(0, isTop ? 2 : -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: WarningWidgetCubit._accent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: WarningWidgetCubit._accent,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'No hay conexión a internet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
