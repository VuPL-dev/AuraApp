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
    const brandColor = Color(0xFFC8102E);
    const bgColor = Color(0xFFFAF8F5);
    final isExpiringSoon = _expireCountdown <= 15;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 52,
                    color: brandColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'XÁC THỰC EMAIL',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Form Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Mã xác thực đã được gửi tới email:',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Countdown Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isExpiringSoon ? brandColor.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: isExpiringSoon ? brandColor : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hết hạn sau: ${_expireCountdown}s',
                              style: TextStyle(
                                color: isExpiringSoon ? brandColor : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // OTP Code Field
                      TextField(
                        controller: _otpController,
                        decoration: InputDecoration(
                          labelText: 'Mã OTP (6 số)',
                          labelStyle: const TextStyle(fontSize: 14),
                          prefixIcon: const Icon(Icons.pin_outlined, color: brandColor, size: 22),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: brandColor, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 18, letterSpacing: 4.0, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Verify Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleVerify,
                        child: _isLoading 
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Xác thực',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Resend Code Link / Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Không nhận được mã? ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: (_isLoading || !_canResend) ? null : _handleResend,
                      child: Text(
                        _canResend ? 'Gửi lại mã' : 'Gửi lại sau ${_cooldown}s',
                        style: TextStyle(
                          color: _canResend ? brandColor : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: _canResend ? TextDecoration.underline : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Back to Login Link
                TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                  icon: const Icon(Icons.arrow_back, size: 16, color: brandColor),
                  label: const Text(
                    'Quay lại Đăng nhập',
                    style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
