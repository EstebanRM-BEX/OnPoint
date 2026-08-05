import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Resultado de una grabación de audio.
class AudioRecordResult {
  final String path;
  final Duration duration;
  const AudioRecordResult(this.path, this.duration);
}

/// Muestra la hoja de grabación de voz. Devuelve el audio grabado o `null` si
/// se canceló / no hubo permiso.
Future<AudioRecordResult?> showAudioRecorderSheet(BuildContext context) {
  return showModalBottomSheet<AudioRecordResult>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AudioRecorderView(),
  );
}

class _AudioRecorderView extends StatefulWidget {
  const _AudioRecorderView();

  @override
  State<_AudioRecorderView> createState() => _AudioRecorderViewState();
}

class _AudioRecorderViewState extends State<_AudioRecorderView> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _starting = true;
  bool _denied = false;
  bool _permanentlyDenied = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      // Pedimos el permiso con permission_handler (estándar del proyecto) en
      // lugar del interno de record, para un manejo consistente y detectar el
      // caso "denegado permanentemente".
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() {
          _starting = false;
          _denied = true;
          _permanentlyDenied = status.isPermanentlyDenied;
        });
        return;
      }
      final dir = await getTemporaryDirectory();
      _path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: _path!);
      setState(() => _starting = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _denied = true;
        });
      }
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  Future<void> _send() async {
    _timer?.cancel();
    final duration = _elapsed;
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    final result = path ?? _path;
    if (!mounted) return;
    if (result == null || duration.inMilliseconds < 500) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, AudioRecordResult(result, duration));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: _denied
            ? _deniedView()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PulsingMic(active: !_starting),
                  const SizedBox(height: 14),
                  Text(
                    _starting ? 'Preparando…' : _fmt(_elapsed),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Grabando nota de voz…',
                      style: TextStyle(fontSize: 12.5, color: Colors.black45)),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancel,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: red,
                            side: const BorderSide(color: red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _starting ? null : _send,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Enviar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColorApp,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openSettings() async {
    // Cerramos la hoja primero para no dejar rutas colgando al ir a Ajustes.
    _close();
    await openAppSettings();
  }

  Widget _deniedView() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const Icon(Icons.mic_off_rounded, color: red, size: 40),
          const SizedBox(height: 10),
          const Text(
            'Sin permiso de micrófono',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            _permanentlyDenied
                ? 'El permiso está bloqueado. Habilítalo en los ajustes de la app para enviar notas de voz.'
                : 'Necesitamos el micrófono para enviar notas de voz.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (_permanentlyDenied)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _close,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: lightGrey),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _openSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorApp,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Abrir ajustes'),
                  ),
                ),
              ],
            )
          else
            TextButton(
              onPressed: _close,
              style: TextButton.styleFrom(foregroundColor: primaryColorApp),
              child: const Text('Entendido'),
            ),
        ],
      );
}

/// Icono de micrófono con anillo pulsante mientras graba.
class _PulsingMic extends StatefulWidget {
  final bool active;
  const _PulsingMic({required this.active});

  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final scale = widget.active ? 1 + (_c.value * 0.25) : 1.0;
        return Container(
          width: 78,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: red.withValues(alpha: 0.10 + (_c.value * 0.10)),
          ),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: red,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }
}
