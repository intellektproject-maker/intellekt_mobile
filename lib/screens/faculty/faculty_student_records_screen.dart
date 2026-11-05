import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/colors.dart';
import 'faculty_manage_attendance_screen.dart';

class FacultyStudentRecordsScreen extends StatefulWidget {
  final String facultyId;
  const FacultyStudentRecordsScreen({super.key, required this.facultyId});
  @override
  State<FacultyStudentRecordsScreen> createState() => _FacultyStudentRecordsScreenState();
}

class _FacultyStudentRecordsScreenState extends State<FacultyStudentRecordsScreen> {
  final _api = ApiClient();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _classes = [], _students = [];
  String? _classKey;
  bool _loadingClasses = true, _loadingStudents = false;
  String? _error;
  @override
  void initState() { super.initState(); _loadClasses(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _loadClasses() async {
    try {
      final res = await _api.get('/classes');
      _classes = res.data is List ? (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingClasses = false); }
  }

  Future<void> _loadStudents() async {
    if (_classKey == null) return;
    final parts = _classKey!.split('||');
    setState(() { _loadingStudents = true; _error = null; });
    try {
      final res = await _api.get('/student-records', queryParameters: {'className': parts.length > 1 ? parts[1] : '', 'board': parts.first});
      if (res.data is! List) throw Exception('Unexpected student records response.');
      _students = (res.data as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) { _error = e.toString().replaceFirst('Exception: ', ''); }
    finally { if (mounted) setState(() => _loadingStudents = false); }
  }

  String _subject(Map<String, dynamic> m) {
    final subject = (m['subject_name'] ?? '').toString().toLowerCase();
    final code = (m['test_code'] ?? '').toString().toUpperCase();
    if (subject.contains('math') || code.contains('M')) return 'Maths';
    if (subject.contains('physics') || code.contains('P')) return 'Physics';
    return (m['subject_name'] ?? '-').toString();
  }
  double _percent(Map<String, dynamic> m) {
    final obtained = double.tryParse(m['marks_obtained']?.toString() ?? '');
    final total = double.tryParse(m['total_marks']?.toString() ?? '');
    if (obtained == null || total == null || total <= 0) return 0;
    return obtained / total * 100;
  }
  String _average(List<Map<String, dynamic>> marks, String subject) {
    final values = marks.where((m) => _subject(m) == subject).toList();
    if (values.isEmpty) return 'N/A';
    return '${(values.map(_percent).reduce((a,b) => a+b) / values.length).toStringAsFixed(2)}%';
  }
  pw.Widget _card(String title, List<pw.Widget> children) => pw.Container(
    width: double.infinity, padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#1C4D96'), width: .6), borderRadius: pw.BorderRadius.circular(5)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0C3D91'), borderRadius: pw.BorderRadius.circular(3)), child: pw.Text(title, style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8), ...children,
    ]),
  );

  Future<void> _downloadReport(Map<String, dynamic> student) async {
    final roll = (student['roll_no'] ?? '').toString();
    if (roll.isEmpty) return;
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await _api.get('/student-record-report/${Uri.encodeComponent(roll)}');
      final data = Map<String, dynamic>.from(response.data as Map);
      final person = Map<String, dynamic>.from(data['student'] as Map);
      final attendance = Map<String, dynamic>.from(data['attendance'] as Map);
      final marks = (data['marks'] as List? ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      final present = int.tryParse(attendance['present_days']?.toString() ?? '') ?? 0;
      final absent = int.tryParse(attendance['absent_days']?.toString() ?? '') ?? 0;
      final totalDays = present + absent;
      final attendancePct = totalDays == 0 ? '0.00' : (present * 100 / totalDays).toStringAsFixed(2);
      final overall = marks.isEmpty ? '0.00' : (marks.map(_percent).reduce((a,b) => a+b) / marks.length).toStringAsFixed(2);
      final today = DateTime.now();
      final reportDate = '${today.day.toString().padLeft(2,'0')} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][today.month-1]} ${today.year}';
      final doc = pw.Document();
      final navy = PdfColor.fromHex('#000351');
      final blue = PdfColor.fromHex('#0C3D91');
      pw.Widget subjectTable(String subject) {
        final rows = marks.where((m) => _subject(m) == subject).take(5).toList();
        return pw.TableHelper.fromTextArray(
          headers: [subject, 'Marks', 'Total', '%'],
          data: rows.isEmpty ? [['No records','-','-','-']] : rows.map((m) => [(m['test_code'] ?? '-').toString(), (m['marks_obtained'] ?? '-').toString(), (m['total_marks'] ?? '-').toString(), '${_percent(m).toStringAsFixed(1)}%']).toList(),
          headerDecoration: pw.BoxDecoration(color: blue),
          headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
          cellStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.center,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: .4),
        );
      }
      doc.addPage(pw.Page(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 22), build: (_) {
        return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Text('Intellekt Academy', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 23, color: navy, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3), pw.Text('STUDENT REPORT', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8), pw.Text('Report Date : $reportDate', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7)),
          pw.SizedBox(height: 10),
          _card('STUDENT DETAILS', [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Roll No : ${person['roll_no'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 5), pw.Text('Name : ${person['name'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 5), pw.Text('Class : ${person['board'] ?? '-'}-${person['class'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
              ])),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Phone : ${person['phone'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 5), pw.Text('Email : ${person['email'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 5), pw.Text('Report Date : $reportDate', style: const pw.TextStyle(fontSize: 8)),
              ])),
            ]),
          ]),
          pw.SizedBox(height: 10),
          _card('TEST PERFORMANCE', [
            pw.Center(child: pw.Text('Overall Average : $overall%', style: pw.TextStyle(fontSize: 9, color: blue, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 8),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(child: pw.Column(children: [pw.Text('Maths Avg : ${_average(marks,'Maths')}', style: pw.TextStyle(fontSize: 8, color: blue)), pw.SizedBox(height: 5), subjectTable('Maths')])),
              pw.SizedBox(width: 10),
              pw.Expanded(child: pw.Column(children: [pw.Text('Physics Avg : ${_average(marks,'Physics')}', style: pw.TextStyle(fontSize: 8, color: blue)), pw.SizedBox(height: 5), subjectTable('Physics')])),
            ]),
          ]),
          pw.SizedBox(height: 10),
          _card('ATTENDANCE SUMMARY', [
            pw.Row(children: [
              pw.Expanded(child: pw.Column(children: [
                pw.Text('Attendance Percentage', style: pw.TextStyle(fontSize: 8, color: blue, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Container(width: 72, height: 72, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.grey300, width: 9), color: PdfColors.white),
                  child: pw.Center(child: pw.Text('${attendancePct}%', style: pw.TextStyle(fontSize: 12, color: blue, fontWeight: pw.FontWeight.bold)))),
                pw.SizedBox(height: 5), pw.Text('Present: $present', style: const pw.TextStyle(fontSize: 7)), pw.Text('Absent: $absent', style: const pw.TextStyle(fontSize: 7)),
              ])),
              pw.SizedBox(width: 14),
              pw.Expanded(child: pw.Column(children: [
                pw.Text('Attendance Trend', style: pw.TextStyle(fontSize: 8, color: blue, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                  pw.Container(width: 24, height: math.max(4.0, present / math.max(1, math.max(present, absent)) * 54).toDouble(), color: PdfColors.green),
                  pw.SizedBox(width: 18),
                  pw.Container(width: 24, height: math.max(4.0, absent / math.max(1, math.max(present, absent)) * 54).toDouble(), color: PdfColors.red),
                ]),
                pw.SizedBox(height: 4), pw.Text('Present       Absent', style: const pw.TextStyle(fontSize: 7)),
                pw.SizedBox(height: 10), pw.Text('Total Working Days : $totalDays', style: const pw.TextStyle(fontSize: 7)),
                pw.Text('Attendance % : ${attendancePct}%', style: const pw.TextStyle(fontSize: 7)),
              ])),
            ]),
          ]),
          pw.SizedBox(height: 10),
          _card('REMARKS', [pw.SizedBox(height: 28), pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(children: [
            pw.Container(width: 75, height: .5, color: PdfColors.black), pw.SizedBox(height: 3),
            pw.Text('Signature', style: const pw.TextStyle(fontSize: 7)), pw.Text('INTELLEKT ACADEMY', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
          ]))]),
        ]);
      }));
      final bytes = await doc.save();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Printing.sharePdf(bytes: bytes, filename: '${roll}_report.pdf');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate report: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _students.where((s) => '${s['name'] ?? s['student_name'] ?? ''} ${s['roll_no'] ?? ''}'.toLowerCase().contains(query)).toList();
    return DefaultTabController(
      length: 2,
      child: Scaffold(backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Student Records'),
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          actions: [IconButton(onPressed: _loadStudents, icon: const Icon(Icons.refresh))],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Student Records'),
              Tab(text: 'Attendance Report'),
            ],
          ),
        ),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: AppColors.surface, elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          if (_loadingClasses) const LinearProgressIndicator(),
          DropdownButtonFormField<String>(value: _classKey, isExpanded: true, decoration: const InputDecoration(labelText: 'Select class', border: OutlineInputBorder()),
            items: _classes.map((c) { final b = (c['board'] ?? '').toString(); final cl = (c['class'] ?? c['class_name'] ?? '').toString(); return DropdownMenuItem(value: '$b||$cl', child: Text('$b-$cl')); }).toList(),
            onChanged: (v) { setState(() { _classKey = v; _students = []; }); if (v != null) _loadStudents(); }),
          const SizedBox(height: 12),
          TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Search by name or roll number', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
        ]))),
        if (_error != null) Card(color: Colors.red.shade50, child: ListTile(title: const Text('Could not load records'), subtitle: Text(_error!))),
        if (_loadingStudents) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loadingStudents && _students.isEmpty) const Card(child: ListTile(title: Text('Select a class to view student records.'))),
        ...visible.map((s) => Card(color: AppColors.surface, elevation: 0, child: ListTile(
          title: Text((s['name'] ?? s['student_name'] ?? 'Student').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('Roll No: ${s['roll_no'] ?? '-'} • Phone: ${s['phone'] ?? '-'}'),
          trailing: FilledButton.tonalIcon(
            onPressed: () => _downloadReport(s),
            style: FilledButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF', style: TextStyle(color: Colors.white)),
          ),
        ))),
          ]),
          FacultyManageAttendanceScreen(facultyId: widget.facultyId, embedded: true),
        ]),
      ),
    );
  }
}