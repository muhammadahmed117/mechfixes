import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks AI advice aloud (works in release APK).
class SpeechOutputService {
  SpeechOutputService() {
    _tts.setCompletionHandler(() {
      _speaking = false;
      onSpeakingChanged?.call(false);
    });
    _tts.setCancelHandler(() {
      _speaking = false;
      onSpeakingChanged?.call(false);
    });
    _tts.setErrorHandler((message) {
      debugPrint('[SpeechOutput] Error: $message');
      _speaking = false;
      onSpeakingChanged?.call(false);
    });
  }

  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  void Function(bool value)? onSpeakingChanged;

  bool get isSpeaking => _speaking;

  Future<void> speak(String text, {required bool romanUrdu}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await stop();
    await _tts.setLanguage(romanUrdu ? 'en-IN' : 'en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _speaking = true;
    onSpeakingChanged?.call(true);
    await _tts.speak(trimmed);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
    onSpeakingChanged?.call(false);
  }

  void dispose() {
    _tts.stop();
  }
}
