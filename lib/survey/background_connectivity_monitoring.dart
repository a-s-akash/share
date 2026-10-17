import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/session_context_controller.dart';
import 'background_sync_manager.dart';

class InternetStatusNotifier extends StateNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  InternetStatusNotifier() : super(false) {
    _init();
  }

  void _init() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOnline = state;
      final isNowOnline = results.any((r) => r != ConnectivityResult.none);
      state = isNowOnline;

      // Enqueue a WorkManager one-off task the moment connectivity is restored
      // so queued attendance, surveys, and images sync without waiting for
      // the 30-minute periodic window.
      if (!wasOnline && isNowOnline) {
        log('Connectivity restored — enqueuing immediate background sync task');
        BackgroundSyncWorkManager.triggerImmediateSync();
      }
    });

    // Initial check
    Connectivity().checkConnectivity().then((results) {
      if (results is List<ConnectivityResult>) {
        state = results.any((r) => r != ConnectivityResult.none);
      } else if (results is ConnectivityResult) {
        // For backward compatibility
        state = results != ConnectivityResult.none;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final internetStatusProvider =
    StateNotifierProvider<InternetStatusNotifier, bool>(
  (ref) => InternetStatusNotifier(),
);

class ConnectivityBanner extends ConsumerWidget {
  final Widget child;
  const ConnectivityBanner({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(internetStatusProvider);
    final mode = ref.watch(sessionContextController).mode;

    // final double topPadding =
    //     MediaQuery.of(context).padding.top + kToolbarHeight;

    final showMode = mode != null;
    final showOffline = !isOnline;

    return Column(
      children: [
        if (showMode || showOffline)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 6,
              children: [
                if (showMode)
                  _StatusIndicator(
                    icon: mode == AppMode.installation
                        ? Icons.build_circle_outlined
                        : Icons.handyman_outlined,
                    color: const Color(0xFF1565C0),
                    label: '${mode.label} Mode',
                  ),
                if (showMode && showOffline)
                  Container(
                    width: 1,
                    height: 14,
                    color: Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.4),
                  ),
                if (showOffline)
                  _StatusIndicator(
                    icon: Icons.cloud_off,
                    color: Theme.of(context).tabBarTheme.indicatorColor ??
                        Theme.of(context).primaryColor,
                    label: 'Offline!',
                  ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
