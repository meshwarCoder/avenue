import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState(this.locale);

  @override
  List<Object?> get props => [locale];
}
