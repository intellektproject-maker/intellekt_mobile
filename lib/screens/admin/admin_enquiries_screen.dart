import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';

class AdminEnquiriesScreen extends StatefulWidget {
  const AdminEnquiriesScreen({super.key});

  @override
  State<AdminEnquiriesScreen> createState() => _AdminEnquiriesScreenState();
}

class _AdminEnquiriesScreenState extends State<AdminEnquiriesScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String? _error;
  String _status = 'All';

  static const List<String> _statuses = ['All', 'Pending', 'Admission In Progress', 'Admitted'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get('/enquiries');
      if (response.data is! List) {
        throw Exception('The server returned an unexpected enquiries response.');
      }
      final items = (response.data as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (!mounted) return;
      setState(() { _all = items; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _all.where((item) {
      final status = (item['status'] ?? 'Pending').toString();
      if (_status != 'All' && status != _status) return false;
      if (query.isEmpty) return true;
      final searchable = [
        item['student_name'], item['enq_id'], item['mobile_number'],
        item['class_board'], item['school_name'], item['parent_name']
      ].whereType<Object>().join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  void _showDetails(Map<String, dynamic> item) {
    final fields = <String, String>{
      'Enquiry ID': (item['enq_id'] ?? item['id'] ?? '-').toString(),
      'Student': (item['student_name'] ?? '-').toString(),
      'Batch': (item['batch'] ?? '-').toString(),
      'Class / Board': (item['class_board'] ?? '-').toString(),
      'School': (item['school_name'] ?? '-').toString(),
      'Date of birth': (item['date_of_birth'] ?? '-').toString(),
      'Subjects': (item['subjects'] ?? '-').toString(),
      'Academic year': '${item['academic_year_from'] ?? '-'} - ${item['academic_year_to'] ?? '-'}',
      'Parent': (item['parent_name'] ?? '-').toString(),
      'Phone': (item['mobile_number'] ?? '-').toString(),
      'Secondary contact': (item['secondary_contact'] ?? '-').toString(),
      'Reference': (item['reference'] ?? '-').toString(),
      'Status': (item['status'] ?? 'Pending').toString(),
      'Notes': (item['comment'] ?? item['reason'] ?? '-').toString(),
    };
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Text('Enquiry details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close)),
              ]),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: fields.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(width: 125, child: Text(entry.key, style: const TextStyle(color: AppColors.textSecondary))),
                        Expanded(child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w600))),
                      ]),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enquiries'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name, enquiry ID, phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty ? null : IconButton(
                  onPressed: () { _searchController.clear(); setState(() {}); },
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: _statuses.map((status) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: ChoiceChip(
                  label: Text(status),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                  selectedColor: const Color(0xFFE8EAF6),
                  labelStyle: TextStyle(color: _status == status ? AppColors.primary : AppColors.textSecondary),
                ),
              )).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.textSecondary),
                          const SizedBox(height: 10),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _load, child: const Text('Retry')),
                        ]),
                      ))
                    : items.isEmpty
                        ? const Center(child: Text('No enquiries match these filters.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final status = (item['status'] ?? 'Pending').toString();
                                final name = (item['student_name'] ?? 'Unnamed student').toString();
                                final batch = (item['batch'] ?? 'Regular Batch').toString();
                                return Card(
                                  color: AppColors.surface,
                                  elevation: 0,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFE8EAF6),
                                      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Text('${item['enq_id'] ?? 'No enquiry ID'} • ${item['class_board'] ?? '-'}\n$batch • $status'),
                                    ),
                                    isThreeLine: true,
                                    trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
                                    onTap: () => _showDetails(item),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
