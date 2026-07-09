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

  Future<void> _toggleUserStatus(Map<String, dynamic> user, bool newStatus) async {
    final actionName = newStatus ? 'khôi phục' : 'vô hiệu hóa';
    final actionBtn = newStatus ? 'Khôi phục' : 'Khóa';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn $actionName tài khoản này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(actionBtn, style: TextStyle(color: newStatus ? Colors.green : Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await TokenStorage.getAccessToken();
      final body = {
        'full_name': user['full_name'],
        'role': user['role'],
        'is_active': newStatus,
      };
      
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/users/${user['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã $actionName tài khoản')));
          _fetchUsers();
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi $actionName tài khoản')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    String selectedRole = user['role'] ?? 'CUSTOMER';
    bool isActive = user['is_active'] ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Sửa tài khoản'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ tên'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Quyền (Role)'),
                    items: const [
                      DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                      DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                      DropdownMenuItem(value: 'CUSTOMER', child: Text('CUSTOMER')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Đang hoạt động (is_active)'),
                    value: isActive,
                    onChanged: (val) => setStateDialog(() => isActive = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final token = await TokenStorage.getAccessToken();
                    final body = {
                      'full_name': nameCtrl.text,
                      'role': selectedRole,
                      'is_active': isActive,
                    };
                    final response = await http.put(
                      Uri.parse('${ApiConstants.baseUrl}/users/${user['id']}'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode(body),
                    );

                    if (response.statusCode == 200) {
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
                        _fetchUsers();
                      }
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại')));
                    }
                  } catch (e) {
                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        }
      ),
    );
  }

  int get _totalUsers => _users.length;
  int get _activeUsers => _users.where((u) => (u['is_active'] ?? true) == true).length;
  int get _inactiveUsers => _users.where((u) => (u['is_active'] ?? true) == false).length;
  int get _adminUsers => _users.where((u) => u['role'] == 'ADMIN').length;

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF3c4b64),
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            color: const Color(0xFF303c54),
            padding: const EdgeInsets.only(bottom: 20),
            alignment: Alignment.bottomCenter,
            child: const Text(
              'Aura Admin',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white70),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.white70),
            title: const Text('Users', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(top: BorderSide(color: color, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.grey.shade400, size: 24),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Tổng Users', _totalUsers.toString(), const Color(0xFF321fdb), Icons.people),
              const SizedBox(width: 16),
              _buildStatCard('Active', _activeUsers.toString(), const Color(0xFF2eb85c), Icons.check_circle_outline),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Inactive', _inactiveUsers.toString(), const Color(0xFFe55353), Icons.block),
              const SizedBox(width: 16),
              _buildStatCard('Admins', _adminUsers.toString(), const Color(0xFF3399ff), Icons.admin_panel_settings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200))
            ),
            child: const Text('Danh sách tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('Không có tài khoản nào.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(0),
                      itemCount: _users.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isActive = user['is_active'] ?? true;
                        
                        // Badge CoreUI colors
                        Color roleColor;
                        if (user['role'] == 'ADMIN') roleColor = const Color(0xFFe55353); // Danger
                        else if (user['role'] == 'STAFF') roleColor = const Color(0xFF3399ff); // Info
                        else roleColor = const Color(0xFF9da5b1); // Secondary

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isActive ? const Color(0xFF321fdb) : Colors.grey.shade400,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            user['full_name'] ?? 'No Name', 
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                              color: isActive ? Colors.black87 : Colors.grey,
                            )
                          ),
                          subtitle: Text(user['email'], style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: roleColor,
                                      borderRadius: BorderRadius.circular(20), // Pill shape
                                    ),
                                    child: Text(
                                      user['role'] ?? 'CUSTOMER',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isActive ? const Color(0xFF2eb85c) : const Color(0xFFe55353),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.black54),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showEditUserDialog(user);
                                  } else if (val == 'toggle') {
                                    _toggleUserStatus(user, !isActive);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                  PopupMenuItem(
                                    value: 'toggle', 
                                    child: Text(isActive ? 'Khóa (Vô hiệu hóa)' : 'Khôi phục tài khoản'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Light background for dashboard
      drawer: _buildDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87), // Dark icons for drawer toggle
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1, // Subtle shadow
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatCards(),
          Expanded(child: _buildUserList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Mở form thêm mới User
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng tạo User đang được phát triển.')));
        },
        backgroundColor: const Color(0xFF321fdb),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
