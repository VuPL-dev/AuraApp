import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'notifications_screen.dart';

const _kPrimary = Color(0xFFC8102E);

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await TokenStorage.getEmail();
    if (mounted) setState(() => _email = email ?? '');
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text('Tài khoản', style: TextStyle(color: Colors.white)),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
            ),
            child: Row(children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFFFD700),
                child: Icon(Icons.person, color: _kPrimary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(_email,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _menuTile(
            icon: Icons.receipt_long_outlined,
            label: 'Lịch sử đơn hàng',
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
          ),
          _menuTile(
            icon: Icons.notifications_outlined,
            label: 'Thông báo',
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const SizedBox(height: 16),
          _menuTile(
            icon: Icons.logout,
            label: 'Đăng xuất',
            color: Colors.red,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _kPrimary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
