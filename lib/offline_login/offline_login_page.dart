import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:schnell_luminator/offline_login/biometric_service.dart';
import 'package:schnell_luminator/utils/constants.dart';
import '../env.dart';
import '../utils/asset_folder.dart';
import '../utils/dialog_box.dart';
import '../utils/error_messages.dart';
import '../utils/utility.dart';

class OfflineLoginPage extends ConsumerStatefulWidget {
  const OfflineLoginPage({super.key});

  @override
  ConsumerState<OfflineLoginPage> createState() => _OfflineLoginPageState();
}

class _OfflineLoginPageState extends ConsumerState<OfflineLoginPage>
    with WidgetsBindingObserver {
  AuthMethodSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMethods();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User may have just set up PIN/fingerprint in Settings — refresh summary
      _loadMethods();
    }
  }

  Future<void> _loadMethods() async {
    final s = await BiometricService.getAuthMethodSummary();
    if (mounted) setState(() => _summary = s);
  }

  Future<void> _showSecurityWarning() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Security Setup Required'),
        content: const Text(
          'No biometrics or screen lock is set up on this device.\n\n'
          'Please enable fingerprint, face unlock, or a PIN/password '
          'in your device settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              const AndroidIntent(
                action: 'android.settings.SECURITY_SETTINGS',
              ).launch();
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  void _showAuthSheet() {
    final s = _summary;
    if (s == null || !s.hasAnyMethod) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthBottomSheet(
        summary: s,
        onAuthenticated: () {
          ref.read(loginController).proceedAfterAuth(context, ref);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final isLoading = ref.watch(loginController).loginLoader;
    final username = ref.watch(loginController).userMail;

    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            SizedBox(height: h / 15),

            // Logo
            Center(
              child: SizedBox(
                height: h / 3.9,
                width: w / 2,
                child: Image.asset(logoImage),
              ),
            ),
            SizedBox(height: h / 33),
            Center(
              child: Text('Luminator',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            // SizedBox(height: h / 20),

            // // Fingerprint icon + username
            // Center(
            //   child: Icon(Icons.fingerprint,
            //       size: 72, color: Theme.of(context).primaryColor),
            // ),
            SizedBox(height: h / 13),
            if (username.isNotEmpty)
              Center(
                child: Text(
                  username,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).secondaryHeaderColor),
                ),
              ),

            SizedBox(height: h / 25),

            // Continue button
            SizedBox(
              height: h / 17,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Theme.of(context).canvasColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: _summary == null
                          ? null
                          : !_summary!.hasAnyMethod
                              ? _showSecurityWarning
                              : _showAuthSheet,
                      child: const Text('Continue With Existing User',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
            ),

            const SizedBox(height: 14),

            // New user
            SizedBox(
              height: h / 17,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  final isOnline = await Utility.isConnected();
                  if (!context.mounted) return;
                  if (isOnline) {
                    await ref.read(loginController).clearLoginFieldValues();
                    Navigator.of(context).pushNamed(loginRoute);
                  } else {
                    await snackBar(context, ErrorMessages.offlineErrorTitle,
                        ErrorMessages.offlineErrorMessage);
                  }
                },
                child: Text('Login As New User',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),

            SizedBox(height: h / 12),
            Center(
              child: Text(
                baseURL.contains('iotpro')
                    ? 'Version: $appVersion - Beta'
                    : 'Version: $appVersion',
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Auth bottom sheet ─────────────────────────────────────────────────────────

class _AuthBottomSheet extends StatefulWidget {
  const _AuthBottomSheet({
    required this.summary,
    required this.onAuthenticated,
  });

  final AuthMethodSummary summary;
  final VoidCallback onAuthenticated;

  @override
  State<_AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<_AuthBottomSheet> {
  bool _loading = false;
  String? _errorMsg;

  Future<void> _authenticate({required bool biometricOnly}) async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final success =
        await BiometricService.authenticate(biometricOnly: biometricOnly);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context); // close sheet
      widget.onAuthenticated();
    } else {
      setState(() {
        _loading = false;
        _errorMsg = 'Authentication failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final hasBiometrics = s.hasFingerprint || s.hasFace;
    // PIN only: device is secured but no biometrics enrolled (Scenarios 4 & 6)
    final pinOnly = !hasBiometrics && s.hasPin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Gray header bar ───────────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              pinOnly
                  ? 'Please Unlock with PIN or Pattern'
                  : 'Please Unlock with biometrics',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
            ),
          ),
        ),

        // ── White card ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: Colors.white,
          padding:
              const EdgeInsets.only(top: 28, left: 24, right: 24, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Authentication required',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verify identity',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                'Please authenticate to go to next screen',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 32),

              // ── Primary circle(s) ─────────────────────────────────────────
              // Scenario 1: fingerprint only   → 1 fingerprint circle
              // Scenario 2: face only          → 1 face circle
              // Scenario 3: fingerprint + face → 2 circles side by side
              // Scenario 4/6: PIN only         → 1 dialpad circle (no "Use PIN" link)
              if (hasBiometrics)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (s.hasFingerprint)
                      _AuthCircle(
                        icon: Icons.fingerprint,
                        label: 'Touch the fingerprint\nsensor',
                        loading: _loading,
                        onTap: () => _authenticate(biometricOnly: true),
                      ),
                    if (s.hasFingerprint && s.hasFace)
                      const SizedBox(width: 36),
                    if (s.hasFace)
                      _AuthCircle(
                        icon: Icons.face_retouching_natural,
                        label: 'Look at the\nfront camera',
                        loading: _loading,
                        onTap: () => _authenticate(biometricOnly: true),
                      ),
                  ],
                )
              else if (pinOnly)
                _AuthCircle(
                  icon: Icons.dialpad,
                  label: 'Enter your PIN\nor Pattern',
                  loading: _loading,
                  onTap: () => _authenticate(biometricOnly: false),
                ),

              const SizedBox(height: 20),

              // ── Error ─────────────────────────────────────────────────────
              if (_errorMsg != null) ...[
                Text(
                  _errorMsg!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 10),
              ],

              // ── "Use PIN" secondary link ──────────────────────────────────
              if (hasBiometrics && s.hasPin)
                TextButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() {
                            _loading = true;
                            _errorMsg = null;
                          });
                          final navigator = Navigator.of(context);
                          final success =
                              await BiometricService.authenticateWithPin();
                          if (!mounted) return;
                          if (success) {
                            navigator.pop();
                            widget.onAuthenticated();
                          } else {
                            setState(() {
                              _loading = false;
                              _errorMsg =
                                  'Authentication failed. Please try again.';
                            });
                          }
                        },
                  child: Text(
                    'Use PIN',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable auth circle button ───────────────────────────────────────────────

class _AuthCircle extends StatelessWidget {
  const _AuthCircle({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: loading ? null : onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: loading ? Colors.grey.shade400 : const Color(0xFF4A4A4A),
              shape: BoxShape.circle,
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.white),
                  )
                : Icon(icon, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
