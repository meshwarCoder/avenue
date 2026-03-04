import 'package:avenue/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/core/logic/theme_cubit.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:avenue/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:avenue/features/settings/presentation/cubit/settings_state.dart';
import 'package:avenue/features/settings/presentation/views/feedback_view.dart';
import 'package:avenue/core/localization/locale_cubit.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 8),
          Center(
            child: SvgPicture.asset(
              fit: BoxFit.scaleDown,
              'assets/icon/avenue.svg',
              height: 100,
              width: 100,
              semanticsLabel: 'Avenue Logo',
            ),
          ),
          const SizedBox(height: 24),
          _buildBetaBanner(context),
          const SizedBox(height: 16),
          _buildFeedbackSection(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppLocalizations.of(context)!.general),
          _buildSettingItem(
            context,
            icon: Icons.language_rounded,
            title: AppLocalizations.of(context)!.language,
            subtitle: _getLanguageName(
              context.watch<LocaleCubit>().state.locale.languageCode,
            ),
            onTap: () => _showLanguagePicker(context),
          ),
          _buildSettingItem(
            context,
            icon: Icons.palette_outlined,
            title: AppLocalizations.of(context)!.themeMode,
            subtitle: _getThemeModeName(
              context,
              context.watch<ThemeCubit>().state,
            ),
            onTap: () => _showThemePicker(context),
          ),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.calendar_today_rounded,
                    title: AppLocalizations.of(context)!.startOfWeek,
                    subtitle: _getDayName(context, state.weekStartDay),
                    onTap: () => _showWeekStartPicker(context),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.access_time_rounded,
                    title: AppLocalizations.of(context)!.timeSystem,
                    subtitle: state.is24HourFormat
                        ? AppLocalizations.of(context)!.hour24
                        : AppLocalizations.of(context)!.hour12,
                    onTap: () => _showTimeFormatPicker(context),
                  ),
                ],
              );
            },
          ),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.notifications_none_rounded,
                    title: AppLocalizations.of(context)!.notifications,
                    subtitle: state.notificationsEnabled
                        ? AppLocalizations.of(context)!.on
                        : AppLocalizations.of(context)!.off,
                    trailing: Switch(
                      value: state.notificationsEnabled,
                      onChanged: (val) => context
                          .read<SettingsCubit>()
                          .updateNotificationsEnabled(val),
                    ),
                    onTap: () => context
                        .read<SettingsCubit>()
                        .updateNotificationsEnabled(
                          !state.notificationsEnabled,
                        ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppLocalizations.of(context)!.account),
          _buildSettingItem(
            context,
            icon: Icons.person_outline_rounded,
            title: AppLocalizations.of(context)!.profileDetails,
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.logout_rounded,
            title: AppLocalizations.of(context)!.logout,
            titleColor: Colors.redAccent,
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.logout),
                  content: Text(AppLocalizations.of(context)!.logoutConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        AppLocalizations.of(context)!.logout,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                context.read<AuthCubit>().signOut();
              }
            },
          ),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              if (!state.isDev) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    AppLocalizations.of(context)!.devOptions,
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.smart_toy_outlined,
                    title: AppLocalizations.of(context)!.aiModel,
                    subtitle: state.aiModel,
                    onTap: () => _showModelEditor(context, state.aiModel),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.key_outlined,
                    title: AppLocalizations.of(context)!.cloudApiKey,
                    subtitle: AppLocalizations.of(context)!.setUpdateServerKey,
                    onTap: () => _showApiKeyEditor(context),
                  ),
                  const SizedBox(height: 16),
                  _buildDevSearchField(context, state),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icon/avenue.svg',
                  height: 48,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.onSurface.withOpacity(0.2),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.versionInfo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetaBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamTan.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.creamTan.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.creamTan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.betaVersion,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.creamTan,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.betaNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppColors.deepPurple.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.deepPurple.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FeedbackView()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.deepPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.feedback_outlined,
                  color: isDark ? Colors.white : AppColors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.helpImprove,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepPurple,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.feedbackSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white : AppColors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: isDark ? Colors.white : AppColors.slatePurple,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              titleColor ?? (isDark ? Colors.white : theme.colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }

  String _getThemeModeName(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.system:
        return l10n.systemDefault;
    }
  }

  void _showThemePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final themeCubit = context.read<ThemeCubit>();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.themeMode,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildThemeOption(
                context,
                l10n.light,
                Icons.light_mode_rounded,
                ThemeMode.light,
                themeCubit,
              ),
              _buildThemeOption(
                context,
                l10n.dark,
                Icons.dark_mode_rounded,
                ThemeMode.dark,
                themeCubit,
              ),
              _buildThemeOption(
                context,
                l10n.systemDefault,
                Icons.brightness_auto_rounded,
                ThemeMode.system,
                themeCubit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final localeCubit = context.read<LocaleCubit>();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectLanguage,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildLanguageOption(context, l10n.english, 'en', localeCubit),
              _buildLanguageOption(context, l10n.arabic, 'ar', localeCubit),
              _buildLanguageOption(context, l10n.spanish, 'es', localeCubit),
              _buildLanguageOption(context, l10n.french, 'fr', localeCubit),
              _buildLanguageOption(context, l10n.german, 'de', localeCubit),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String code,
    LocaleCubit cubit,
  ) {
    final isSelected = cubit.state.locale.languageCode == code;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.deepPurple : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.deepPurple)
          : null,
      onTap: () {
        cubit.changeLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  String _getLanguageName(String code) {
    if (code == 'ar') return "العربية";
    if (code == 'es') return "Español";
    if (code == 'fr') return "Français";
    if (code == 'de') return "Deutsch";
    return "English";
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    ThemeMode mode,
    ThemeCubit cubit,
  ) {
    final isSelected = cubit.state == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.deepPurple : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.deepPurple : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.deepPurple)
          : null,
      onTap: () {
        cubit.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  String _getDayName(BuildContext context, int day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
      case DateTime.saturday:
        return l10n.saturday;
      case DateTime.sunday:
        return l10n.sunday;
      case DateTime.monday:
        return l10n.monday;
      case DateTime.tuesday:
        return l10n.tuesday;
      case DateTime.wednesday:
        return l10n.wednesday;
      case DateTime.thursday:
        return l10n.thursday;
      case DateTime.friday:
        return l10n.friday;
      default:
        return l10n.saturday;
    }
  }

  void _showWeekStartPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final settingsCubit = context.read<SettingsCubit>();
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.startOfWeek,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                for (int day = 1; day <= 7; day++)
                  ListTile(
                    title: Text(
                      _getDayName(context, day),
                      style: TextStyle(
                        fontWeight: settingsCubit.state.weekStartDay == day
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: settingsCubit.state.weekStartDay == day
                            ? AppColors.deepPurple
                            : null,
                      ),
                    ),
                    trailing: settingsCubit.state.weekStartDay == day
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.deepPurple,
                          )
                        : null,
                    onTap: () {
                      settingsCubit.updateWeekStartDay(day);
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimeFormatPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final settingsCubit = context.read<SettingsCubit>();
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.timeSystem,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.access_time_rounded),
                  title: Text(AppLocalizations.of(context)!.hour12),
                  subtitle: const Text("1:00 PM, 12:00 AM"),
                  trailing: !settingsCubit.state.is24HourFormat
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.deepPurple,
                        )
                      : null,
                  onTap: () {
                    settingsCubit.updateTimeFormat(false);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text(AppLocalizations.of(context)!.hour24),
                  subtitle: const Text("13:00, 24:00"),
                  trailing: settingsCubit.state.is24HourFormat
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.deepPurple,
                        )
                      : null,
                  onTap: () {
                    settingsCubit.updateTimeFormat(true);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showModelEditor(BuildContext context, String currentModel) {
    final controller = TextEditingController(text: currentModel);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.changeAiModel),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.modelName,
            hintText: 'e.g. google/gemini-3-pro-preview',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final newModel = controller.text.trim();
              if (newModel.isNotEmpty) {
                context.read<SettingsCubit>().updateAiModel(newModel);
              }
              Navigator.pop(dialogContext);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  void _showApiKeyEditor(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.updateCloudApiKey),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.apiKeyEditorNotice,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.newApiKey,
                hintText: 'sk-or-v1-...',
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final newKey = controller.text.trim();
              if (newKey.isNotEmpty) {
                context.read<SettingsCubit>().updateAiApiKey(newKey);
              }
              Navigator.pop(dialogContext);
            },
            child: Text(AppLocalizations.of(context)!.saveToCloud),
          ),
        ],
      ),
    );
  }

  Widget _buildDevSearchField(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchTasksDev,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state.isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (val) => context.read<SettingsCubit>().testSearch(val),
        ),
        if (state.searchResults != null && state.searchResults!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: state.searchResults!.map((res) {
                return ListTile(
                  dense: true,
                  title: Text(res['name'] ?? 'No Name'),
                  subtitle: Text(res['id'] ?? 'No ID'),
                  trailing: res['importance'] != null
                      ? Text(res['importance'].toString().toUpperCase())
                      : null,
                );
              }).toList(),
            ),
          ),
        ] else if (state.searchQuery != null && !state.isSearching) ...[
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.noResultsFound),
        ],
      ],
    );
  }
}
