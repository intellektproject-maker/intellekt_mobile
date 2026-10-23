import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_routes.dart';
import '../../core/constants/colors.dart';

class RegisteredStudentsScreen extends StatefulWidget {
  const RegisteredStudentsScreen({super.key});

  @override
  State<RegisteredStudentsScreen> createState() => _RegisteredStudentsScreenState();
}

class _RegisteredStudentsScreenState extends State<RegisteredStudentsScreen> {
  final _api = ApiClient();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  String? _error;
  String _className = '';
  String _board = '';
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get(ApiRoutes.registeredStudents, queryParameters: {
        if (_className.isNotEmpty) 'className': _className,
        if (_board.isNotEmpty) 'board': _board,
        if (_date != null) 'date': _date!.toIso8601String().split('T').first,
      });
      final data = response.data;
      if (data is! List) throw Exception('Unexpected response from server.');
      _students = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final rows = _students.where((s) {
      final text = '${s['student_name'] ?? s['name'] ?? ''} ${s['roll_no'] ?? ''} ${s['phone'] ?? ''}'.toLowerCase();
      return text.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registered Students'),
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh')],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search name, roll number or phone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: const Text('Could not load registered students'),
                  subtitle: Text(_error!),
                  trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? Center(child: Text(_error == null ? 'No registered students found.' : 'Check your connection and try again.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final s = rows[index];
                            final name = (s['student_name'] ?? s['name'] ?? 'Student').toString();
                            final roll = (s['roll_no'] ?? '-').toString();
                            final cls = (s['class'] ?? s['class_name'] ?? '-').toString();
                            final board = (s['board'] ?? '-').toString();
                            return Card(
                              elevation: 0,
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: .1),
                                  child: Text(name.isEmpty ? 'S' : name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text('Roll No: $roll\nClass: $board-$cls', maxLines: 2),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}
