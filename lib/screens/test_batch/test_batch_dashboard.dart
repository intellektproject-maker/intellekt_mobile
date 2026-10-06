import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/test_batch_provider.dart';
import '../../services/push_notification_service.dart';
import '../../routes/app_routes.dart';

class TestBatchDashboard extends StatefulWidget {
  const TestBatchDashboard({super.key});

  @override
  State<TestBatchDashboard> createState() => _TestBatchDashboardState();
}

class _TestBatchDashboardState extends State<TestBatchDashboard> {
  String _rollNo = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final id = auth.user?.id.trim().toUpperCase() ?? '';
    if (id.isEmpty || !auth.isTestBatchStudent || _rollNo == id) return;
    _rollNo = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TestBatchProvider>().load(_rollNo);
    });
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestBatchProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Test Batch Dashboard'),
        actions: [
          _TestBatchNotificationBell(rollNo: _rollNo),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(_rollNo),
        child: provider.isLoading && provider.student == null
            ? ListView(
                children: const [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : provider.error != null && provider.student == null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 180),
                      Text(
                        'Unable to load Test Batch data.\nPlease refresh and try again.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ProfileCard(student: provider.student ?? {}),
                      const SizedBox(height: 14),
                      Card(
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            child: Icon(Icons.app_registration_outlined),
                          ),
                          title: const Text(
                            'Test Registration',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                          subtitle: const Text(
                            'View posted tests and register for your test date and slot.',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                          onTap: () => context.push(AppRoutes.testBatchRegistration),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _AcademicSummaryLauncher(
                              title: 'Attendance',
                              value: '${provider.attendancePercentage.toStringAsFixed(1)}%',
                              icon: Icons.assignment_turned_in_outlined,
                              route: AppRoutes.testBatchAttendance,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AcademicSummaryLauncher(
                              title: 'Marks',
                              value: '${provider.marks.length}',
                              icon: Icons.menu_book_outlined,
                              route: AppRoutes.testBatchMarks,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _AcademicSummaryLauncher extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String route;

  const _AcademicSummaryLauncher({
    required this.title,
    required this.value,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push(route),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> student;

  const _ProfileCard({required this.student});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ' + (student['name'] ?? 'Student').toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              _Detail('Roll No', student['roll_no']),
              _Detail('Class', student['class']),
              _Detail('Board', student['board']),
              _Detail('Test Series', student['test_series_name']),
            ],
          ),
        ),
      );
}

class _Detail extends StatelessWidget {
  final String label;
  final dynamic value;

  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = value?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label + ': ' + (text.isEmpty ? '-' : text),
        style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
}


class _TestBatchNotificationBell extends StatefulWidget {
  final String rollNo;
  const _TestBatchNotificationBell({required this.rollNo});

  @override
  State<_TestBatchNotificationBell> createState() =>
      _TestBatchNotificationBellState();
}

class _TestBatchNotificationBellState
    extends State<_TestBatchNotificationBell> {
  List<Map<String, dynamic>> _notifications = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didUpdateWidget(covariant _TestBatchNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rollNo != widget.rollNo) _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (widget.rollNo.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final notifications = await PushNotificationService.instance
        .getInAppNotifications(widget.rollNo);
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _loading = false;
    });
  }

  Future<void> _openNotifications() async {
    await _loadNotifications();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_none_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No notifications yet.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final item = _notifications[index];
                          final title = item['title']?.toString() ?? 'INTELLEKT';
                          final body = item['body']?.toString() ?? '';
                          final timestamp = DateTime.tryParse(
                            item['timestamp']?.toString() ?? '',
                          );
                          final timeText = timestamp == null
                              ? ''
                              : timestamp.day.toString().padLeft(2, '0') +
                                  '-' +
                                  timestamp.month.toString().padLeft(2, '0') +
                                  '-' +
                                  timestamp.year.toString() +
                                  ' ' +
                                  timestamp.hour.toString().padLeft(2, '0') +
                                  ':' +
                                  timestamp.minute.toString().padLeft(2, '0');

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 0,
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE8EAF6),
                              foregroundColor: AppColors.primary,
                              child: Icon(Icons.notifications_none_rounded),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                body + (timeText.isEmpty ? '' : '\n' + timeText),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          actions: [
            if (_notifications.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await PushNotificationService.instance
                      .clearInAppNotifications(widget.rollNo);
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (mounted) setState(() => _notifications = const []);
                },
                child: const Text('Clear all'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNotifications = _notifications.isNotEmpty;
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: _openNotifications,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        if (hasNotifications)
          IgnorePointer(
            child: Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 9, right: 9),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
