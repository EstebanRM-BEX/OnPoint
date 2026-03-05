abstract class IAudioService {
  Future<void> playErrorSound();
  Future<void> stopSound();
  Future<void> dispose();
}
