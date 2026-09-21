import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/src/presentation/providers/network_overlay/network_overlay_cubit.dart';
import 'config_card.dart';

/// Interruptor del indicador de red global (NetworkOverlayCubit).
class NetworkIndicatorCard extends StatelessWidget {
  const NetworkIndicatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkOverlayCubit, bool>(
      builder: (context, visible) => ConfigCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColorApp.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.network_check, color: primaryColorApp),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indicador de red',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    visible ? 'Visible en todas las pantallas' : 'Oculto',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: visible,
              activeColor: Colors.white,
              activeTrackColor: primaryColorApp,
              onChanged: (value) =>
                  context.read<NetworkOverlayCubit>().setVisible(value),
            ),
          ],
        ),
      ),
    );
  }
}
