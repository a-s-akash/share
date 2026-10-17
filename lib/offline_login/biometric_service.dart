import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _channel = MethodChannel('com.schnell.luminator/device_credential');

  /// Returns true if the device has at least one secure lock configured.
  static Future<bool> isDeviceSecure() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      log('BiometricService.isDeviceSecure error: $e');
      return false;
    }
  }

  /// Returns the enrolled biometric types (fingerprint, face, iris).
  static Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      log('BiometricService.getAvailableTypes error: $e');
      return [];
    }
  }

  /// Builds a summary of which auth methods are currently active on the device.
  static Future<AuthMethodSummary> getAuthMethodSummary() async {
    final isSecure = await isDeviceSecure();
    if (!isSecure) {
      return const AuthMethodSummary(
          hasFingerprint: false, hasFace: false, hasPin: false);
    }
    final types = await getAvailableTypes();
    return AuthMethodSummary(
      hasFingerprint: types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak),
      hasFace: types.contains(BiometricType.face),
      // Device is secured → PIN / pattern / password is always available
      hasPin: isSecure,
    );
  }

  /// Prompts the user to verify identity.
  ///
  /// [biometricOnly] = true  → fingerprint / face only
  /// [biometricOnly] = false → PIN / pattern / password (+ biometric fallback)
  static Future<bool> authenticate({bool biometricOnly = false}) async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Verify your identity to continue using Luminator',
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      log('BiometricService.authenticate error: $e');
      return false;
    }
  }

  /// Shows the device lock screen (PIN / pattern / password) directly,
  /// bypassing the biometric prompt entirely.
  static Future<bool> authenticateWithPin() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('showDeviceCredential');
      return result ?? false;
    } catch (e) {
      log('BiometricService.authenticateWithPin error: $e');
      // Fallback to local_auth credential flow if channel fails
      return authenticate(biometricOnly: false);
    }
  }
}

class AuthMethodSummary {
  final bool hasFingerprint;
  final bool hasFace;
  final bool hasPin;

  const AuthMethodSummary({
    required this.hasFingerprint,
    required this.hasFace,
    required this.hasPin,
  });

  bool get hasAnyMethod => hasFingerprint || hasFace || hasPin;
}
