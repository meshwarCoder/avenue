import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/core/logic/theme_cubit.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:avenue/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:avenue/features/settings/presentation/cubit/settings_state.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildBetaBanner(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "General"),
          _buildSettingItem(
            context,
            icon: Icons.palette_outlined,
            title: "Theme Mode",
            subtitle: _getThemeModeName(context.watch<ThemeCubit>().state),
            onTap: () => _showThemePicker(context),
          ),
          BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              return Column(
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.calendar_today_rounded,
                    title: "Start of the Week",
                    subtitle: _getDayName(state.weekStartDay),
                    onTap: () => _showWeekStartPicker(context),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.access_time_rounded,
                    title: "Time System",
                    subtitle: state.is24HourFormat ? "24-Hour" : "12-Hour",
                    onTap: () => _showTimeFormatPicker(context),
                  ),
                ],
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.notifications_none_rounded,
            title: "Notifications",
            subtitle: "On",
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Account"),
          _buildSettingItem(
            context,
            icon: Icons.person_outline_rounded,
            title: "Profile Details",
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.logout_rounded,
            title: "Logout",
            titleColor: Colors.redAccent,
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent),
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
          const SizedBox(height: 40),
          Center(
            child: Text(
              "Avenue v0.1.0-beta",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
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
                  "Beta Version",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.creamTan,
                  ),
                ),
                Text(
                  "Avenue is currently in beta. Some features are still being polished.",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.slatePurple,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? theme.colorScheme.primary),
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

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "Light";
      case ThemeMode.dark:
        return "Dark";
      case ThemeMode.system:
        return "System Default";
    }
  }

  void _showThemePicker(BuildContext context) {
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
                "Select Theme",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildThemeOption(
                context,
                "Light",
                Icons.light_mode_rounded,
                ThemeMode.light,
                themeCubit,
              ),
              _buildThemeOption(
                context,
                "Dark",
                Icons.dark_mode_rounded,
                ThemeMode.dark,
                themeCubit,
              ),
              _buildThemeOption(
                context,
                "System Default",
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

  String _getDayName(int day) {
    switch (day) {
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';

      default:
        return 'Saturday';
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
                  "Select Start of Week",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                for (int day = 1; day <= 7; day++)
                  ListTile(
                    title: Text(
                      _getDayName(day),
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
                  "Select Time Format",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.access_time_rounded),
                  title: const Text(
                    "12-Hour",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
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
                  title: const Text(
                    "24-Hour",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
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
}
