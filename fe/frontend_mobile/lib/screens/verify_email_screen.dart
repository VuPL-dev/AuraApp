import 'dart:async';
import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  
  bool _canResend = true;
  int _cooldown = 0;
  int _expireCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        // Handle Resend Cooldown
        if (_cooldown > 0) {
          _cooldown--;
        } else {
          _canResend = true;
        }

        // Handle Expiration Countdown
        if (_expireCountdown > 0) {
          _expireCountdown--;
        } else {
          // Expired
          timer.cancel();
          _handleExpired();
        }
      });
    });
  }

  void _handleExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hết 1 phút, vui lòng đăng ký lại để nhận mã mới!')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final req = VerifyEmailRequest(email: widget.email, otpCode: otp);
    final success = await AuthService.verifyEmail(req);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _timer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xác thực thành công! Vui lòng đăng nhập.')),
      );
      // Navigate to Login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã OTP không đúng hoặc đã hết hạn')),
      );
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    
    setState(() => _isLoading = true);
    final success = await AuthService.resendVerifyEmail(widget.email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại mã xác thực!')),
      );
      // Reset cooldown and expiration
      setState(() {
        _canResend = false;
        _cooldown = 30; // 30s cooldown for resend button
        _expireCountdown = 60; // reset the 1 minute limit
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi thất bại, vui lòng thử lại sau.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mã xác thực đã được gửi tới: ${widget.email}'),
            const SizedBox(height: 8),
            Text(
              'Hết hạn sau: ${_expireCountdown}s',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'Mã OTP (6 số)'),
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Xác thực'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: (_isLoading || !_canResend) ? null : _handleResend,
              child: Text(_canResend ? 'Gửi lại mã' : 'Gửi lại mã sau ${_cooldown}s'),
            )
          ],
        ),
      ),
    );
  }
}
