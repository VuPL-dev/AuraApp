import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../utils/validators.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';
import 'admin_dashboard_screen.dart';
import 'staff_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  int _failedAttempts = 0;
  bool _isLocked = false;
  Timer? _lockTimer;
  int _lockSeconds = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  void _startLockTimer() {
    setState(() {
      _isLocked = true;
      _lockSeconds = 60;
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_lockSeconds > 0) {
          _lockSeconds--;
        } else {
          _isLocked = false;
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleLogin() async {
    if (_isLocked) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final req = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final res = await AuthService.login(req);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success && res.accessToken != null) {
      // Reset attempts
      _failedAttempts = 0;
      // Save token
      await TokenStorage.saveTokens(res.accessToken, null, email: req.email);
      
      // Navigate based on role
      if (mounted) {
        if (res.role == 'ADMIN') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else if (res.role == 'STAFF') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
        }
      }
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _startLockTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai quá 5 lần. Vui lòng đợi 1 phút.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Đăng nhập thất bại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
                enabled: !_isLoading && !_isLocked,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                  return null;
                },
                enabled: !_isLoading && !_isLocked,
              ),
              const SizedBox(height: 24),
              if (_isLocked)
                Text('Khóa đăng nhập: $_lockSeconds giây',
                    style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isLocked) ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Đăng nhập'),
                ),
              ),
              TextButton(
                onPressed: (_isLoading || _isLocked)
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                child: const Text('Chưa có tài khoản? Đăng ký'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
