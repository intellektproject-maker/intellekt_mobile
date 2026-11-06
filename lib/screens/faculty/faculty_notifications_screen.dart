import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../repositories/faculty_task_repository.dart';
import '../../services/push_notification_service.dart';

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
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _archivedNotifications = [];
  bool _loading = true;
  bool _showArchived = false;
  bool _busy = false;
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
      final items = _showArchived
          ? await _repository.getArchivedFacultyNotifications(widget.facultyId)
          : await _repository.getFacultyNotifications(widget.facultyId);
      if (!mounted) return;
      setState(() {
        if (_showArchived) {
          _archivedNotifications = items;
        } else {
          _notifications = items;
        }
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

  Future<void> _switchArchiveView(bool archived) async {
    if (_showArchived == archived) return;
    setState(() {
      _showArchived = archived;
      _loading = true;
      _error = null;
    });
    await _loadNotifications();
  }

  int? _notificationId(Map<String, dynamic> item) {
    final rawId = item['id'];
    return rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    if (notification['is_read'] == true) return;
    final notificationId = _notificationId(notification);
    if (notificationId == null) return;

    try {
      await _repository.markSingleNotificationRead(
        facultyId: widget.facultyId,
        notificationId: notificationId,
      );
      if (!mounted) return;
      setState(() => notification['is_read'] = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update notification.')),
      );
    }
  }

  Future<void> _markAllRead() async {
    if (_busy || _notifications.every((item) => item['is_read'] == true)) return;
    setState(() => _busy = true);
    try {
      await _repository.markAllFacultyNotificationsRead(widget.facultyId);
      if (!mounted) return;
      setState(() {
        for (final item in _notifications) {
          item['is_read'] = true;
        }
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to mark all as read.')),
      );
    }
  }

  Future<void> _archiveAll() async {
    if (_busy || _notifications.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'They will be moved to Archived Notifications. You can restore them later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _repository.archiveAllFacultyNotifications(widget.facultyId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to clear notifications.')),
      );
      return;
    }

    // The server has confirmed the archive operation. Reset the AnimatedList
    // rather than running per-item removals that can throw after the API succeeds.
    if (!mounted) return;
    setState(() {
      _notifications.clear();
      _listKey = GlobalKey<AnimatedListState>();
      _busy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications moved to archive.')),
    );
  }

  Future<void> _restoreNotification(Map<String, dynamic> notification) async {
    final id = _notificationId(notification);
    if (id == null) return;
    try {
      await _repository.restoreFacultyNotification(
        facultyId: widget.facultyId,
        notificationId: id,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to restore notification.')),
      );
      return;
    }

    // Only the restore request is treated as an operation failure. UI updates
    // happen after it succeeds, outside the request's error handler.
    if (!mounted) return;
    setState(() => _archivedNotifications.remove(notification));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification restored.')),
    );
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

  String _formatIstDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
    final hour = ist.hour % 12 == 0 ? 12 : ist.hour % 12;
    final date = '${ist.day.toString().padLeft(2, '0')}/'
        '${ist.month.toString().padLeft(2, '0')}/'
        '${ist.year}';
    final time = '$hour:'
        '${ist.minute.toString().padLeft(2, '0')} '
        '${ist.hour >= 12 ? 'PM' : 'AM'} IST';
    return '$date, $time';
  }

  Widget _buildAnimatedCard(
    Map<String, dynamic> item,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _notificationCard(item),
      ),
    );
  }

  Widget _notificationCard(
    Map<String, dynamic> item, {
    bool archived = false,
  }) {
    final isRead = item['is_read'] == true;
    final createdAt = item['created_at']?.toString() ?? '';
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: archived
            ? null
            : () async {
                await _markRead(item);
                if (!mounted) return;
                PushNotificationService.instance.openNotificationData({
                  'module_name':
                      item['module_name']?.toString() ?? 'notifications',
                  'title': item['title']?.toString() ?? _module(item),
                  'body': item['message']?.toString() ?? '',
                });
              },
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
                        if (!archived && !isRead)
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
                        _formatIstDateTime(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (archived)
                IconButton(
                  tooltip: 'Restore notification',
                  onPressed: () => _restoreNotification(item),
                  icon: const Icon(
                    Icons.restore_outlined,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * .22),
        const Icon(
          Icons.notifications_none_outlined,
          size: 52,
          color: Colors.grey,
        ),
        const SizedBox(height: 12),
        Center(child: Text(message)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((item) => item['is_read'] != true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(_showArchived ? 'Archived Notifications' : 'Notifications'),
        foregroundColor: AppColors.primary,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _loading || _busy
                ? null
                : () => _switchArchiveView(!_showArchived),
            icon: Icon(
              _showArchived ? Icons.inbox_outlined : Icons.archive_outlined,
              size: 19,
            ),
            label: Text(_showArchived ? 'Inbox' : 'Archive'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _emptyState(_error!)
                : _showArchived
                    ? _archivedNotifications.isEmpty
                        ? _emptyState('No archived notifications.')
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _archivedNotifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _notificationCard(
                              _archivedNotifications[index],
                              archived: true,
                            ),
                          )
                    : _notifications.isEmpty
                        ? _emptyState('No notifications yet.')
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            unreadCount == 0
                                                ? 'All notifications are read'
                                                : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${_notifications.length} total',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _busy ||
                                                    unreadCount == 0
                                                ? null
                                                : _markAllRead,
                                            icon: const Icon(
                                              Icons.done_all,
                                              size: 18,
                                            ),
                                            label: const Text('Mark all as read'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: FilledButton.tonalIcon(
                                            onPressed: _busy
                                                ? null
                                                : _archiveAll,
                                            icon: const Icon(
                                              Icons.archive_outlined,
                                              size: 17,
                                            ),
                                            label: const FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'Clear all',
                                                maxLines: 1,
                                                softWrap: false,
                                              ),
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(0, 48),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 10,
                                              ),
                                              tapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: AnimatedList(
                                  key: _listKey,
                                  initialItemCount: _notifications.length,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    16,
                                  ),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemBuilder: (context, index, animation) {
                                    if (index >= _notifications.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _buildAnimatedCard(
                                        _notifications[index],
                                        animation,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
      ),
    );
  }
}
