/// FastAPI diagnostic backend connection settings.
///
/// Android emulator: use `10.0.2.2` (maps to PC localhost).
/// Physical phone APK: set [pcLanIp] to your PC Wi-Fi IP from `ipconfig`.
class DiagnosticApiConfig {
  DiagnosticApiConfig._();

  static const int port = 8000;

  /// Update this when testing APK on a real phone (same Wi-Fi as PC).
  static const String pcLanIp = '192.168.1.8';

  /// Prefer physical-device LAN URL in release APK; emulator URL in debug.
  static String get diagnoseUrl {
    const releaseOverride = String.fromEnvironment('DIAGNOSE_URL');
    if (releaseOverride.isNotEmpty) return releaseOverride;

    // Release APK on a real phone cannot use 10.0.2.2.
    if (const bool.fromEnvironment('dart.vm.product')) {
      return 'http://$pcLanIp:$port/api/diagnose';
    }
    return 'http://10.0.2.2:$port/api/diagnose';
  }
}
