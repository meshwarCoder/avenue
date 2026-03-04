import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locale_repository.dart';
import 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  final LocaleRepository _repository;

  LocaleCubit(this._repository) : super(const LocaleState(Locale('en'))) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final languageCode = await _repository.getSavedLocale();
    if (languageCode != null) {
      emit(LocaleState(Locale(languageCode)));
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (state.locale.languageCode == languageCode) return;

    await _repository.saveLocale(languageCode);
    emit(LocaleState(Locale(languageCode)));
  }
}
