import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    // Precargar el archivo de audio tan pronto como se crea la instancia del servicio
    _initAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _initAudioPlayer() async {
    try {
      // 1. Cargar el asset de forma asíncrona y mantenerlo listo.
      await _audioPlayer.setAsset('assets/audio/error.mp3');
      print("✅ Audio 'error.mp3' precargado y listo para usar.");
    } catch (e) {
      print("❌ Error al precargar el audio: $e");
    }
  }

  // 2. La función de reproducción ahora solo llama al comando play
  Future<void> playErrorSound() async {
    // Volver al inicio del audio (duración 0) para que suene cada vez
    await _audioPlayer.seek(Duration.zero);
    
    // Reproducir el audio instantáneamente, ya que ya fue cargado
    await _audioPlayer.play();

    print("✅ Sonido de error reproducido instantáneamente.");
  }

  Future<void> stopSound() async {
    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}