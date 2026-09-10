import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../repositories/faculty_task_repository.dart';

class FacultyNotificationsScreen extends StatefulWidget {
  final String facultyId;

  const FacultyNotificationsScreen({
    super.key,
    required this.facultyId,
  });

  @override
  State<FacultyNotificationsScreen> createState() =>
      _FacultyNotificationsScreenState();
}

class _FacultyNotificationsScreenState
    extends State<FacultyNotificationsScreen> {
  final FacultyTaskRepository _repository = FacultyTaskRepository();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await _repository.getFacultyNotifications(widget.facultyId);
      if (!mounted) return;
      setState(() {
        _notifications = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load notifications.';
      });
    }
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;

    final rawId = notification['id'];
    final notificationId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (notificationId == null) return;

    try {
      await _repository.markSingleNotificationRead(
        facultyId: widget.facultyId,
        notificationId: notificationId,
      );
      if (!mounted) return;
      setState(() {
        notification['is_read'] = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update notification.')),
      );
    }
  }

  String _message(Map<String, dynamic> item) {
    final message = item['message']?.toString().trim() ?? '';
    return message.isEmpty ? 'You have a new notification.' : message;
  }

  String _module(Map<String, dynamic> item) {
    final value = item['module_name']?.toString().trim() ?? '';
    if (value.isEmpty) return 'Notification';
    return value
        .split('-')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((item) => item['is_read'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Notifications'),
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.sizeOf(context).height * .25),
                      Center(child: Text(_error!)),
                    ],
                  )
                : _notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.sizeOf(context).height * .25),
                          const Icon(Icons.notifications_none_outlined,
                              size: 52, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Center(child: Text('No notifications yet.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _notifications.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Text(
                              unreadCount == 0
                                  ? 'All notifications are read'
                                  : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }

                          final item = _notifications[index - 1];
                          final isRead = item['is_read'] == true;
                          final createdAt = item['created_at']?.toString() ?? '';

                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: isRead ? null : () => _markRead(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isRead
                                            ? Icons.notifications_none_outlined
                                            : Icons.notifications_active_outlined,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _module(item),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _message(item),
                                            style: TextStyle(
                                              color: Colors.grey.shade800,
                                              height: 1.35,
                                            ),
                                          ),
                                          if (createdAt.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              createdAt,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
