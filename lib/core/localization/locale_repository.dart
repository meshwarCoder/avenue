// No imports needed

abstract class LocaleRepository {
  Future<void> saveLocale(String languageCode);
  Future<String?> getSavedLocale();
}
