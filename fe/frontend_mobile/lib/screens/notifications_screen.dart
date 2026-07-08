import 'package:flutter/material.dart';
import '../services/notification_service.dart';

const _kPrimary = Color(0xFFC8102E);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final notifications = await NotificationService.getNotifications(unreadOnly: false);
    if (mounted) setState(() { _notifications = notifications; _loading = false; });
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    _loadNotifications();
  }

  Future<void> _markRead(dynamic notification) async {
    if (notification['is_read'] == true) return;
    await NotificationService.markRead(notification['id']);
    _loadNotifications();
  }

  String _formatDate(dynamic isoDate) {
    final date = DateTime.tryParse(isoDate.toString());
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.white)),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Đọc tất cả', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _notifications.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Không có thông báo nào.', style: TextStyle(color: Colors.grey)),
                ]))
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['is_read'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFFFFF3F3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => _markRead(n),
                          leading: CircleAvatar(
                            backgroundColor: _kPrimary.withOpacity(0.1),
                            child: Icon(Icons.star_outline, color: _kPrimary),
                          ),
                          title: Text(n['title'] ?? '',
                              style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['message'] ?? '', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(_formatDate(n['created_at']),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          trailing: isRead
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
