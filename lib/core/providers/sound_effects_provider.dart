import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SoundEffectsManager {
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _incorrectPlayer = AudioPlayer();
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    _correctPlayer.setSource(AssetSource('audio/answer-correct.mp3'));
    _incorrectPlayer.setSource(AssetSource('audio/incorrect.swf.mp3'));
    _initialized = true;
  }

  static Future<void> playCorrect() async {
    if (!_initialized) _init();
    try {
      await _correctPlayer.stop(); 
      await _correctPlayer.resume();
    } catch (e) {
      // Direct play if resume fails
      _correctPlayer.play(AssetSource('audio/answer-correct.mp3'), mode: PlayerMode.lowLatency);
    }
  }

  static Future<void> playIncorrect() async {
    if (!_initialized) _init();
    try {
      await _incorrectPlayer.stop();
      await _incorrectPlayer.resume();
    } catch (e) {
      // Direct play if resume fails
      _incorrectPlayer.play(AssetSource('audio/incorrect.swf.mp3'), mode: PlayerMode.lowLatency);
    }
  }
}

final soundEffectsProvider = Provider((ref) => SoundEffectsManager());
