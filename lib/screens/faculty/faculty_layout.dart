import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FacultyLayout extends StatefulWidget {
  final Widget child;
  final String facultyId;

  const FacultyLayout({
    super.key,
    required this.child,
    required this.facultyId,
  });

  @override
  State<FacultyLayout> createState() => _FacultyLayoutState();
}

class _FacultyLayoutState extends State<FacultyLayout> {
  bool manageOpen = false;

  bool get isPrivilegedFaculty =>
      widget.facultyId == 'IG001' || widget.facultyId == 'IG002';

  bool isActive(String path) {
    return GoRouterState.of(context).uri.path == path;
  }

  void navigateTo(String path) {
    Navigator.pop(context);

    context.go(
      Uri(
        path: path,
        queryParameters: {
          'id': widget.facultyId,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // ==============================
      // Top App Bar
      // ==============================

      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        elevation: 4,
        title: const Text(
          'INTELLEKT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),

      // ==============================
      // Side Navigation Drawer
      // ==============================

      drawer: Drawer(
        backgroundColor: Colors.white,
        width: 288,
        child: SafeArea(
          child: Column(
            children: [
              // Close Button

              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              // Navigation Items

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  children: [
                    _buildMenuItem(
                      title: 'Profile',
                      path: '/faculty-dashboard/profile',
                      icon: Icons.person_outline,
                    ),

                    _buildMenuItem(
                      title: 'Attendance',
                      path: '/faculty-dashboard/attendance',
                      icon: Icons.calendar_month_outlined,
                    ),

                    _buildMenuItem(
                      title: 'Test',
                      path: '/faculty-dashboard/test',
                      icon: Icons.assignment_outlined,
                    ),

                    // ==============================
                    // Manage Dropdown
                    // ==============================

                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: currentPath.startsWith(
                          '/faculty-dashboard/manage',
                        )
                            ? const Color(0xFFDBEAFE)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: manageOpen,
                        onExpansionChanged: (value) {
                          setState(() {
                            manageOpen = value;
                          });
                        },
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: Text(
                          'Manage',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: currentPath.startsWith(
                              '/faculty-dashboard/manage',
                            )
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF1F2937),
                          ),
                        ),
                        children: [
                          _buildSubMenuItem(
                            title: 'Students',
                            path:
                            '/faculty-dashboard/manage/students',
                          ),
                          _buildSubMenuItem(
                            title: 'Faculty',
                            path:
                            '/faculty-dashboard/manage/faculty',
                          ),
                        ],
                      ),
                    ),

                    // ==============================
                    // Privileged Faculty Items
                    // ==============================

                    if (isPrivilegedFaculty) ...[
                      _buildMenuItem(
                        title: 'Student Record',
                        path:
                        '/faculty-dashboard/student-record',
                        icon: Icons.school_outlined,
                      ),
                      _buildMenuItem(
                        title: 'Enquiries',
                        path: '/faculty-dashboard/enquiries',
                        icon: Icons.question_answer_outlined,
                      ),
                      _buildMenuItem(
                        title: 'Requests',
                        path: '/faculty-dashboard/requests',
                        icon: Icons.request_page_outlined,
                      ),
                    ],

                    // ==============================
                    // Reset Password
                    // ==============================

                    _buildResetPasswordItem(),
                  ],
                ),
              ),

              // ==============================
              // Sign Out Button
              // ==============================

              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ==============================
      // Page Content
      // ==============================

      body: widget.child,
    );
  }

  // ==============================
  // Main Menu Item
  // ==============================

  Widget _buildMenuItem({
    required String title,
    required String path,
    required IconData icon,
  }) {
    final active = isActive(path);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFDBEAFE)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: active
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF374151),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: active
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF1F2937),
          ),
        ),
        onTap: () {
          navigateTo(path);
        },
      ),
    );
  }

  // ==============================
  // Sub Menu Item
  // ==============================

  Widget _buildSubMenuItem({
    required String title,
    required String path,
  }) {
    final active = isActive(path);

    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        right: 8,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFEFF6FF)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF374151),
          ),
        ),
        onTap: () {
          navigateTo(path);
        },
      ),
    );
  }

  // ==============================
  // Reset Password Item
  // ==============================

  Widget _buildResetPasswordItem() {
    final active = isActive('/reset-password');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFDBEAFE)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          Icons.lock_reset_outlined,
          color: active
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF374151),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: active
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF1F2937),
          ),
        ),
        onTap: () {
          Navigator.pop(context);

          context.go(
            Uri(
              path: '/reset-password',
              queryParameters: {
                'id': widget.facultyId,
                'role':
                isPrivilegedFaculty ? 'admin' : 'faculty',
              },
            ).toString(),
          );
        },
      ),
    );
  }
}