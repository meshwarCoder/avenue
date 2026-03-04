import 'package:shared_preferences/shared_preferences.dart';
import 'locale_repository.dart';

class LocaleRepositoryImpl implements LocaleRepository {
  final SharedPreferences sharedPreferences;
  static const String _localeKey = 'app_locale';

  LocaleRepositoryImpl(this.sharedPreferences);

  @override
  Future<void> saveLocale(String languageCode) async {
    await sharedPreferences.setString(_localeKey, languageCode);
  }

  @override
  Future<String?> getSavedLocale() async {
    return sharedPreferences.getString(_localeKey);
  }
}
