import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceInputFailure {
  none,
  permissionDenied,
  permissionPermanentlyDenied,
  pluginMissing,
  unavailable,
  unknown,
}

/// Speech-to-text helper for turning voice into editable text.
class VoiceInputService {
  VoiceInputService();

  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _available = false;
  bool _listening = false;
  VoiceInputFailure lastFailure = VoiceInputFailure.none;
  String lastErrorMessage = '';

  bool get isListening => _listening || _speech.isListening;
  bool get isAvailable => _available;

  Future<bool> ensureMicrophonePermission() async {
    if (kIsWeb) return true;

    try {
      var status = await Permission.microphone.status;
      if (status.isGranted) return true;

      status = await Permission.microphone.request();
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        lastFailure = VoiceInputFailure.permissionPermanentlyDenied;
        lastErrorMessage = 'Microphone permission is permanently denied.';
      } else {
        lastFailure = VoiceInputFailure.permissionDenied;
        lastErrorMessage = 'Microphone permission was denied.';
      }
      return false;
    } catch (error, stackTrace) {
      debugPrint('[VoiceInput] Permission check failed: $error');
      debugPrint('$stackTrace');
      // Fall through — speech_to_text may still prompt on some devices.
      return true;
    }
  }

  Future<bool> initialize({bool force = false}) async {
    if (_initialized && !force) return _available;

    lastFailure = VoiceInputFailure.none;
    lastErrorMessage = '';

    final permissionOk = await ensureMicrophonePermission();
    if (!permissionOk) {
      _initialized = true;
      _available = false;
      return false;
    }

    try {
      _available = await _speech.initialize(
        onError: (error) {
          debugPrint('[VoiceInput] Error: ${error.errorMsg}');
          lastErrorMessage = error.errorMsg;
          _listening = false;
        },
        onStatus: (status) {
          debugPrint('[VoiceInput] Status: $status');
          if (status == 'done' ||
              status == 'notListening' ||
              status == 'doneNoResult') {
            _listening = false;
          }
        },
      );

      if (!_available) {
        lastFailure = VoiceInputFailure.unavailable;
        lastErrorMessage =
            'Speech recognition is not available. Install/enable Google app & Speech Services.';
      }
      _initialized = true;
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('[VoiceInput] MissingPluginException: $error');
      debugPrint('$stackTrace');
      lastFailure = VoiceInputFailure.pluginMissing;
      lastErrorMessage =
          'Voice plugin not loaded. Rebuild a fresh APK (flutter clean && flutter build apk).';
      _available = false;
      _initialized = false;
    } catch (error, stackTrace) {
      debugPrint('[VoiceInput] Init failed: $error');
      debugPrint('$stackTrace');
      lastFailure = VoiceInputFailure.unknown;
      lastErrorMessage = error.toString();
      _available = false;
      _initialized = true;
    }

    return _available;
  }

  Future<String?> _resolveLocaleId(String preferredLocale) async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return null;

      final preferred = preferredLocale.toLowerCase();
      for (final locale in locales) {
        if (locale.localeId.toLowerCase() == preferred) {
          return locale.localeId;
        }
      }
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('en')) {
          return locale.localeId;
        }
      }
      return locales.first.localeId;
    } catch (_) {
      return preferredLocale;
    }
  }

  Future<bool> startListening({
    required void Function(String text) onResult,
    String localeId = 'en_US',
  }) async {
    final ready = await initialize(force: true);
    if (!ready) return false;

    try {
      final resolvedLocale = await _resolveLocaleId(localeId);
      _listening = true;
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _listening = false;
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 4),
          localeId: resolvedLocale,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('[VoiceInput] listen failed: $error');
      debugPrint('$stackTrace');
      _listening = false;
      lastFailure = VoiceInputFailure.unknown;
      lastErrorMessage = error.toString();
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_listening && !_speech.isListening) return;
    await _speech.stop();
    _listening = false;
  }

  Future<void> cancel() async {
    await _speech.cancel();
    _listening = false;
  }

  Future<void> openAppSettingsPage() => openAppSettings();

  void dispose() {
    _speech.cancel();
    _listening = false;
  }
}
