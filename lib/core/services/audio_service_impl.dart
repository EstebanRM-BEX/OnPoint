import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:injectable/injectable.dart';
import '../interfaces/i_audio_service.dart';

@LazySingleton(as: IAudioService)
class AudioServiceImpl implements IAudioService {
  AudioServiceImpl() {
    _initAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setAsset('assets/audio/error.mp3');
      debugPrint("✅ Audio 'error.mp3' precargado y listo para usar.");
    } catch (e) {
      debugPrint("❌ Error al precargar el audio: $e");
    }
  }

  @override
  Future<void> playErrorSound() async {
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.play();
    debugPrint("✅ Sonido de error reproducido instantáneamente.");
  }

  @override
  Future<void> stopSound() async {
    await _audioPlayer.stop();
  }

  @override
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
