import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class BiometricWrapper extends StatefulWidget {
  final Widget child;
  const BiometricWrapper({super.key, required this.child});

  @override
  State<BiometricWrapper> createState() => _BiometricWrapperState();
}

class _BiometricWrapperState extends State<BiometricWrapper> with WidgetsBindingObserver {
  bool _isLocked = !kIsWeb;
  bool _isAuthenticating = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      _authenticate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    
    // When app goes to background, lock it
    if (state == AppLifecycleState.paused) {
      if (!_isAuthenticating) {
        setState(() {
          _isLocked = true;
        });
      }
    }
    
    // When app comes to foreground, authenticate
    if (state == AppLifecycleState.resumed) {
      if (_isLocked && !_isAuthenticating) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });

    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        // If device has no biometric support, just unlock
        setState(() {
          _isLocked = false;
        });
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to access BahiKhata',
      );

      if (authenticated) {
        setState(() {
          _isLocked = false;
        });
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'BahiKhata Locked',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock to continue',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              if (!_isAuthenticating)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: AppButton(
                    label: 'Unlock',
                    icon: Icons.fingerprint,
                    onPressed: _authenticate,
                    variant: AppButtonVariant.secondary,
                  ),
                )
              else
                const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
