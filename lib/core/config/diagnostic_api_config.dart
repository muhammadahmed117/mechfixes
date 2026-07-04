/// FastAPI diagnostic backend connection settings.
///
/// Android emulator: `10.0.2.2` maps to the host machine's `localhost`.
class DiagnosticApiConfig {
  DiagnosticApiConfig._();

  /// Full diagnose endpoint for Android emulator development.
  static const String diagnoseUrl = 'http://10.0.2.2:8000/api/diagnose';
}
