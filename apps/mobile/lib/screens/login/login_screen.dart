import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:email_validator/email_validator.dart';

import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Clean up plaintext password if it exists from previous versions
      await _storage.delete(key: 'cached_password');
      // Save flag and email, NO password
      await _storage.write(key: 'biometric_enabled', value: 'true');
      await _storage.write(key: 'cached_email', value: email);

      _popLogin();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã có lỗi xảy ra kết nối mạng. Vui lòng thử lại sau.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Explicitly update loading state if user cancels Google Sign-In
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      _popLogin();
    } catch (e) {
      setState(() {
        _errorMessage = 'Đăng nhập Google thất bại hoặc không được hỗ trợ.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _errorMessage = 'Thiết bị không hỗ trợ xác thực sinh trắc học.';
        });
        return;
      }

      final enabled = await _storage.read(key: 'biometric_enabled');
      final user = _auth.currentUser; // Firebase persists session automatically

      if (enabled != 'true' || user == null) {
        setState(() {
          _errorMessage = 'Vui lòng đăng nhập bằng Email/Mật khẩu ít nhất một lần.';
        });
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Vui lòng quét vân tay hoặc khuôn mặt để mở khóa',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Firebase session exists -> no need to sign in again, just unlock UI
        _popLogin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi trong quá trình xác thực sinh trắc học.';
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập Email để khôi phục mật khẩu.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _auth.sendPasswordResetEmail(email: email);
      setState(() {
        _errorMessage = 'Đã gửi email khôi phục mật khẩu. Vui lòng kiểm tra hộp thư.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gửi email khôi phục thất bại. Vui lòng kiểm tra lại.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _popLogin() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF020617)]
                : const [Color(0xFFE3F2FD), Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand Logo Area
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HVAC Pro',
                    style: GoogleFonts.firaCode(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hệ thống tra cứu chuyên nghiệp',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.slate[400] : AppColors.slate[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphism Card (with maximum width constraint)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate[950]!.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Đăng nhập',
                                  style: GoogleFonts.firaCode(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.slate[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Email Input
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập Email.';
                                    }
                                    if (!EmailValidator.validate(value)) {
                                      return 'Định dạng Email không hợp lệ.';
                                    }
                                    return null;
                                  },
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Mật khẩu',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu.';
                                    }
                                    if (value.length < 6) {
                                      return 'Mật khẩu phải chứa ít nhất 6 ký tự.';
                                    }
                                    return null;
                                  },
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 12),

                                // Forgot Password Link
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isLoading ? null : _resetPassword,
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),

                                if (_errorMessage != null) ...[
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Login Button
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _isLoading ? null : _loginWithEmail,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: isDark ? AppColors.slate[800] : AppColors.slate[300],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Hoặc đăng nhập bằng',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.slate[500] : AppColors.slate[600],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: isDark ? AppColors.slate[800] : AppColors.slate[300],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Google & Biometric buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google button
                                    _buildRoundSocialButton(
                                      icon: ClipOval(
                                        child: Image.asset(
                                          'assets/images/google_logo.png',
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      onTap: _isLoading ? null : _loginWithGoogle,
                                    ),
                                    const SizedBox(width: 24),

                                    // Fingerprint/Biometrics Button
                                    _buildRoundSocialButton(
                                      icon: Icon(
                                        Icons.fingerprint,
                                        size: 28,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      onTap: _isLoading ? null : _authenticateBiometrics,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundSocialButton({
    required Widget icon,
    required VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isLoading ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.slate[900]!.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            border: Border.all(
              color: isDark ? AppColors.slate[800]! : AppColors.slate[200]!,
            ),
          ),
          child: icon,
        ),
      ),
    );
  }
}
