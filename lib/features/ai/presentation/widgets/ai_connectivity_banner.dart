import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/logic/app_connectivity_cubit.dart';
import '../../../../core/logic/app_connectivity_state.dart';
import '../../../../core/logic/app_banner_cubit.dart';
import '../../../../core/logic/app_banner_state.dart';

/// AI-specific connectivity banner widget.
///
/// Responsibilities:
/// - Display offline state (red banner, persistent while offline)
/// - Display connection restored state (green banner, auto-hide after 2 seconds)
/// - Handle smooth animations (no flicker, no layout jump)
/// - Only rebuild banner widget, not parent screen
/// - Detect offline → online transition precisely
/// - Cancel resources on dispose (no memory leaks)
class AiConnectivityBanner extends StatefulWidget {
  const AiConnectivityBanner({super.key});

  @override
  State<AiConnectivityBanner> createState() => _AiConnectivityBannerState();
}

class _AiConnectivityBannerState extends State<AiConnectivityBanner> {
  /// Tracks previous offline state to detect transitions.
  /// Start with null to distinguish from initial load.
  bool? _previousIsOffline;

  @override
  void dispose() {
    super.dispose();
  }

  /// Show green "connection restored" banner for 2 seconds
  /// Delegates to global AppBannerCubit which handles timer lifecycle
  void _showConnectionRestoredBanner() {
    final bannerCubit = context.read<AppBannerCubit>();
    final banner = AppBanner(
      id: 'ai_connection_restored',
      isPersistent: false,
      displayDuration: const Duration(seconds: 2),
    );
    bannerCubit.showTemporary(banner);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AppConnectivityCubit, AppConnectivityState>(
      listenWhen: (previous, current) =>
          previous.isOffline != current.isOffline,
      listener: (context, state) {
        final currentIsOffline = state.isOffline;
        final bannerCubit = context.read<AppBannerCubit>();

        // First load: just track state, don't show any banner
        if (_previousIsOffline == null) {
          _previousIsOffline = currentIsOffline;
          return;
        }

        // Explicit comparison: offline → online transition
        if (_previousIsOffline == true && currentIsOffline == false) {
          // Guarantee: show green banner for 2 seconds via global cubit
          _showConnectionRestoredBanner();
        }
        // Explicit comparison: online → offline transition
        // Must immediately cancel green banner and reset state
        else if (_previousIsOffline == false && currentIsOffline == true) {
          // Global cubit clears any pending temporary banner
          bannerCubit.clear();
        }

        // Update previous state for next transition detection
        _previousIsOffline = currentIsOffline;
      },
      child: BlocBuilder<AppConnectivityCubit, AppConnectivityState>(
        buildWhen: (previous, current) =>
            previous.isOffline != current.isOffline,
        builder: (context, connectivityState) {
          return BlocBuilder<AppBannerCubit, AppBanner?>(
            builder: (context, bannerState) {
              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  // Priority: offline banner > green banner > nothing
                  child: connectivityState.isOffline
                      ? _OfflineBanner(
                          theme: theme,
                          key: const ValueKey('offline'),
                        )
                      : (bannerState?.id == 'ai_connection_restored'
                            ? _ConnectionRestoredBanner(
                                theme: theme,
                                key: const ValueKey('restored'),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty'))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Red banner shown when offline.
class _OfflineBanner extends StatelessWidget {
  final ThemeData theme;

  const _OfflineBanner({required this.theme, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.red.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${AppLocalizations.of(context)!.noInternet}. ${AppLocalizations.of(context)!.aiUnavailable}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green banner shown when connection is restored.
/// Auto-hides after 2 seconds.
class _ConnectionRestoredBanner extends StatelessWidget {
  final ThemeData theme;

  const _ConnectionRestoredBanner({required this.theme, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.green.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.wifi_rounded, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.backOnline,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
