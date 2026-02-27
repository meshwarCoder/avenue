import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/app_connectivity_cubit.dart';
import '../logic/app_connectivity_state.dart';

/// Global connectivity state provider that doesn't depend on BuildContext.
///
/// This allows widgets to check connectivity state without being wrapped
/// in a specific provider widget.
class GlobalConnectivity {
  static final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);

  static void setOffline(bool value) {
    isOffline.value = value;
  }

  static bool get offline => isOffline.value;
}

/// A professional offline indicator with slide-down animation.
///
/// Features:
/// - Error Red color scheme
/// - Border radius for modern look
/// - Subtle shadow
/// - Slide-down entrance animation
/// - SafeArea padding for status bar
/// - English text only (per requirements)
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.red, // Salmon red
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'No internet connection',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Green banner shown briefly when connection returns.
/// Auto-dismisses after 2 seconds via cubit timer.
class BackOnlineBanner extends StatefulWidget {
  const BackOnlineBanner({super.key});

  @override
  State<BackOnlineBanner> createState() => _BackOnlineBannerState();
}

class _BackOnlineBannerState extends State<BackOnlineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50), // Green
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Back online',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapper that displays connectivity banners as floating overlays.
///
/// Shows:
/// - Red banner when offline
/// - Green banner briefly when connection returns
class ConnectivityBannerWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConnectivityCubit, AppConnectivityState>(
      builder: (context, state) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (state.isOffline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: const OfflineBanner(),
              ),
            if (state.justCameOnline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: const BackOnlineBanner(),
              ),
          ],
        );
      },
    );
  }
}
