import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wms_app/core/constants/colors.dart';

/// Burbuja de nota de voz con reproducción (play/pause + progreso).
///
/// Cada burbuja gestiona su propio [AudioPlayer], que se carga de forma
/// perezosa (al primer play) y se libera en dispose.
class AudioMessageBubble extends StatefulWidget {
  final String source;
  final Duration duration;
  final bool isSentByMe;

  const AudioMessageBubble({
    super.key,
    required this.source,
    required this.duration,
    required this.isSentByMe,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _loaded = false;
  bool _loading = false;

  bool get _isNetwork => widget.source.startsWith('http');

  Color get _fg => widget.isSentByMe ? Colors.white : primaryColorApp;
  Color get _bg => widget.isSentByMe ? primaryColorApp : secondary;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }
    if (!_loaded) {
      setState(() => _loading = true);
      try {
        if (_isNetwork) {
          await _player.setUrl(widget.source);
        } else {
          await _player.setFilePath(widget.source);
        }
        _loaded = true;
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (mounted) setState(() => _loading = false);
    }
    // Si terminó, reiniciar antes de reproducir.
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return InkWell(
                  onTap: _toggle,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.isSentByMe ? Colors.white24 : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _loading
                        ? Padding(
                            padding: const EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _fg),
                          )
                        : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: _fg,
                            size: 24,
                          ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snapshot) {
                      final total = _player.duration ?? widget.duration;
                      final pos = snapshot.data ?? Duration.zero;
                      final ratio = total.inMilliseconds == 0
                          ? 0.0
                          : (pos.inMilliseconds / total.inMilliseconds)
                              .clamp(0.0, 1.0);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 4,
                              backgroundColor: widget.isSentByMe
                                  ? Colors.white38
                                  : Colors.black12,
                              valueColor: AlwaysStoppedAnimation(_fg),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.mic, size: 13, color: _fg),
                              const SizedBox(width: 3),
                              Text(
                                _fmt(pos == Duration.zero ? total : pos),
                                style: TextStyle(fontSize: 11, color: _fg),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
