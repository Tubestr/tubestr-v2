import 'package:just_audio/just_audio.dart';

class EditorAudioPreviewService {
  EditorAudioPreviewService({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  String? _currentAssetPath;

  String? get currentAssetPath => _currentAssetPath;

  bool get isPlaying => _player.playing;

  Future<bool> togglePreview({
    required String assetPath,
    double volume = 0.75,
  }) async {
    if (_currentAssetPath == assetPath && _player.playing) {
      await stop();
      return false;
    }

    if (_currentAssetPath != assetPath) {
      await _player.setAsset(assetPath);
      _currentAssetPath = assetPath;
    }

    await _player.setVolume(volume);
    await _player.seek(Duration.zero);
    await _player.play();
    return true;
  }

  Future<void> updateVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
