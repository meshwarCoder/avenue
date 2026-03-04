import 'package:flutter/material.dart';
import 'package:avenue/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/constants.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        SvgPicture.asset(
          'assets/icon/avenue.svg',
          height: 120,
          width: 120,
          semanticsLabel: AppLocalizations.of(context)!.appName,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: isDark ? Colors.white : AppColors.deepPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
