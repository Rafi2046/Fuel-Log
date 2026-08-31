/// Google Places API key — pass at build/run time:
/// `flutter run --dart-define=GOOGLE_PLACES_API_KEY=your_key`
abstract final class GooglePlacesConfig {
  static const apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  static bool get isConfigured => apiKey.isNotEmpty;
}
