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
  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredUsers {
    return _users.where((u) {
      final email = (u['email'] as String? ?? '').toLowerCase();
      final name = (u['full_name'] as String? ?? '').toLowerCase();
      final matchesSearch = email.contains(_searchQuery.toLowerCase()) ||
          name.contains(_searchQuery.toLowerCase());

      final role = u['role'] as String? ?? 'CUSTOMER';
      final matchesRole = _selectedRoleFilter == 'ALL' || role == _selectedRoleFilter;

      return matchesSearch && matchesRole;
    }).toList();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn $actionName tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : const Color(0xFFC8102E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionBtn),
          ),
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
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    String selectedRole = user['role'] ?? 'CUSTOMER';
    bool isActive = user['is_active'] ?? true;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Sửa tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Họ tên',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ tên';
                        return null;
                      },
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Quyền (Role)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                        DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                        DropdownMenuItem(value: 'CUSTOMER', child: Text('CUSTOMER')),
                      ],
                      onChanged: isSaving ? null : (val) {
                        if (val != null) setStateDialog(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Đang hoạt động', style: TextStyle(fontSize: 14)),
                      value: isActive,
                      activeColor: const Color(0xFFC8102E),
                      contentPadding: EdgeInsets.zero,
                      onChanged: isSaving ? null : (val) => setStateDialog(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8102E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSaving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setStateDialog(() => isSaving = true);
                  try {
                    final token = await TokenStorage.getAccessToken();
                    final body = {
                      'full_name': nameCtrl.text.trim(),
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
                  } finally {
                    setStateDialog(() => isSaving = false);
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'CUSTOMER';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Thêm tài khoản mới', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập Email';
                        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                        if (!emailRegex.hasMatch(val.trim())) return 'Email không đúng định dạng';
                        return null;
                      },
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Họ tên',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ tên';
                        return null;
                      },
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Tối thiểu 8 ký tự',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                        if (val.length < 8) return 'Mật khẩu phải dài tối thiểu 8 ký tự';
                        return null;
                      },
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Quyền (Role)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                        DropdownMenuItem(value: 'STAFF', child: Text('STAFF')),
                        DropdownMenuItem(value: 'CUSTOMER', child: Text('CUSTOMER')),
                      ],
                      onChanged: isSaving ? null : (val) {
                        if (val != null) setStateDialog(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8102E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSaving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setStateDialog(() => isSaving = true);
                  try {
                    final token = await TokenStorage.getAccessToken();
                    final response = await http.post(
                      Uri.parse('${ApiConstants.baseUrl}/users'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        'email': emailCtrl.text.trim(),
                        'password': passwordCtrl.text,
                        'full_name': nameCtrl.text.trim(),
                        'role': selectedRole,
                      }),
                    );

                    if (response.statusCode == 201) {
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo tài khoản thành công')));
                        _fetchUsers();
                      }
                    } else {
                      final data = jsonDecode(response.body);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Tạo tài khoản thất bại')));
                      }
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  } finally {
                    setStateDialog(() => isSaving = false);
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Tạo'),
              ),
            ],
          );
        },
      ),
    );
  }

  int get _totalUsers => _users.length;
  int get _activeUsers => _users.where((u) => (u['is_active'] ?? true) == true).length;
  int get _inactiveUsers => _users.where((u) => (u['is_active'] ?? true) == false).length;
  int get _adminUsers => _users.where((u) => u['role'] == 'ADMIN').length;

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFFC8102E),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, color: Color(0xFFC8102E), size: 36),
            ),
            accountName: Text('Quản trị viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text('admin@aura.com'),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: Colors.white70),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline, color: Colors.white70),
            title: const Text('Quản lý người dùng', style: TextStyle(color: Colors.white)),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Tổng Users', _totalUsers.toString(), const Color(0xFFC8102E), Icons.people),
              const SizedBox(width: 12),
              _buildStatCard('Đang hoạt động', _activeUsers.toString(), const Color(0xFF2EB85C), Icons.check_circle_outline),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Bị khóa', _inactiveUsers.toString(), Colors.orange, Icons.block),
              const SizedBox(width: 12),
              _buildStatCard('Quản trị', _adminUsers.toString(), const Color(0xFF3399FF), Icons.admin_panel_settings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên hoặc email...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFC8102E), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC8102E), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('Quản trị (Admin)', 'ADMIN'),
                const SizedBox(width: 8),
                _buildFilterChip('Nhân viên (Staff)', 'STAFF'),
                const SizedBox(width: 8),
                _buildFilterChip('Khách hàng', 'CUSTOMER'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRoleFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFFC8102E),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFFC8102E) : Colors.grey.shade200,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRoleFilter = value;
          });
        }
      },
    );
  }

  Widget _buildUserList() {
    final list = _filteredUsers;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                Text(
                  'Tổng cộng: ${list.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text('Không tìm thấy tài khoản nào.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(0),
                        itemCount: list.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
                        itemBuilder: (context, index) {
                          final user = list[index];
                          final isActive = user['is_active'] ?? true;
                          
                          Color roleColor;
                          if (user['role'] == 'ADMIN') roleColor = const Color(0xFFC8102E);
                          else if (user['role'] == 'STAFF') roleColor = const Color(0xFF3399FF);
                          else roleColor = const Color(0xFF9DA5B1);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isActive ? const Color(0xFFC8102E).withOpacity(0.1) : Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                color: isActive ? const Color(0xFFC8102E) : Colors.grey.shade600,
                              ),
                            ),
                            title: Text(
                              user['full_name'] ?? 'No Name', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                color: isActive ? Colors.black87 : Colors.grey.shade500,
                              )
                            ),
                            subtitle: Text(user['email'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: roleColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user['role'] ?? 'CUSTOMER',
                                        style: const TextStyle(
                                          fontSize: 10,
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
                                const SizedBox(width: 8),
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
      backgroundColor: Colors.grey.shade100,
      drawer: _buildDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
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
          _buildSearchAndFilters(),
          Expanded(child: _buildUserList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFFC8102E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
