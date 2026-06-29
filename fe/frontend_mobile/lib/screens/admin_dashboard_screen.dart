import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../services/token_storage.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        _goToLogin();
        return;
      }
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _users = data;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFC8102E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Không có tài khoản nào.'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFC8102E),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(user['full_name'] ?? 'No Name'),
                      subtitle: Text(user['email']),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user['role'] == 'ADMIN'
                              ? Colors.red.shade100
                              : user['role'] == 'STAFF'
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['role'] ?? 'CUSTOMER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: user['role'] == 'ADMIN'
                                ? Colors.red.shade800
                                : user['role'] == 'STAFF'
                                    ? Colors.blue.shade800
                                    : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
