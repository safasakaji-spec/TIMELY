import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SchoolApp());
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام متابعة التأخير',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'JO'),
      supportedLocales: const [Locale('ar', 'JO')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class LateRecord {
  final String id;
  final String date;
  final String studentName;
  final String gradeClass;

  LateRecord({
    required this.id,
    required this.date,
    required this.studentName,
    required this.gradeClass,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'studentName': studentName,
        'gradeClass': gradeClass,
      };

  factory LateRecord.fromMap(Map<String, dynamic> map) => LateRecord(
        id: map['id'],
        date: map['date'],
        studentName: map['studentName'],
        gradeClass: map['gradeClass'],
      );
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  DateTime selectedDate = DateTime.now();
  String schoolName = "المدرسة الثانوية الشاملة";
  String teacherName = "المعلمة الفاضلة (لجنة النظام)";
  
  List<LateRecord> allRecords = [];
  final _nameController = TextEditingController();
  
  // قائمة الشعب والصفوف حسب طلبك
  final List<String> classesList = [
    'سابع (أ)', 'سابع (ب)', 'سابع (ج)',
    'ثامن (أ)', 'ثامن (ب)', 'ثامن (ج)',
    'تاسع (أ)', 'تاسع (ب)', 'تاسع (ج)', 'تاسع (د)',
    'عاشر (أ)', 'عاشر (ب)', 'عاشر (ج)', 'عاشر (د)',
    'أول ثانوي (أ)', 'أول ثانوي (ب)', 'أول ثانوي (ج)', 'أول ثانوي (د)',
    'توجيهي (أ)', 'توجيهي (ب)', 'توجيهي (ج)'
  ];

  String? selectedClass;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsData = prefs.getString('records');
    setState(() {
      schoolName = prefs.getString('schoolName') ?? schoolName;
      teacherName = prefs.getString('teacherName') ?? teacherName;
      if (recordsData != null) {
        final List decoded = jsonDecode(recordsData);
        allRecords = decoded.map((item) => LateRecord.fromMap(item)).toList();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(allRecords.map((e) => e.toMap()).toList());
    await prefs.setString('records', encoded);
    await prefs.setString('schoolName', schoolName);
    await prefs.setString('teacherName', teacherName);
  }

  void _addRecord() {
    if (_nameController.text.trim().isEmpty || selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الطالبة واختيار الشعبة')),
      );
      return;
    }

    final newRecord = LateRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      studentName: _nameController.text.trim(),
      gradeClass: selectedClass!,
    );

    setState(() {
      allRecords.add(newRecord);
      _nameController.clear();
    });
    _saveData();
  }

  void _deleteRecord(String id) {
    setState(() {
      allRecords.removeWhere((item) => item.id == id);
    });
    _saveData();
  }

  // حساب عدد مرات التأخير لكل طالبة
  Map<String, int> get tardinessCounts {
    Map<String, int> counts = {};
    for (var record in allRecords) {
      counts[record.studentName] = (counts[record.studentName] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    String formattedSelectedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    List<LateRecord> todayRecords =
        allRecords.where((r) => r.date == formattedSelectedDate).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal[800],
          toolbarHeight: 120,
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  const Text('وزارة التربية والتعليم - المملكة الأردنية الهاشمية',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 4),
              Text(schoolName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('سجل التأخير اليومي | مسؤول اللجان: $teacherName',
                  style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.edit_calendar), text: "التسجيل اليومي"),
              Tab(icon: Icon(Icons.warning_amber_rounded), text: "السجل التراكمي والتنبيهات"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // الشاشة الأولى: التسجيل اليومي والرزنامة
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // اختيار التاريخ
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month, color: Colors.teal),
                      title: Text('التاريخ المحدد: $formattedSelectedDate',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: TextButton(
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: const Text('تغيير التاريخ'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // نموذج إضافة طالبة
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'اسم الطالبة الثلاثي/الرباعي',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_add),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'الصف والشعبة',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.class_),
                            ),
                            items: classesList.map((String c) {
                              return DropdownMenuItem<String>(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) => setState(() => selectedClass = val),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[700],
                              minimumSize: const Size.fromHeight(45),
                            ),
                            onPressed: _addRecord,
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('تسجيل التأخير اليوم',
                                style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('قائمة التأخير لهذا اليوم:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Expanded(
                    child: todayRecords.isEmpty
                        ? const Center(child: Text('لا يوجد تسجيلات لهذا اليوم'))
                        : ListView.builder(
                            itemCount: todayRecords.length,
                            itemBuilder: (context, index) {
                              final item = todayRecords[index];
                              int totalTimes = tardinessCounts[item.studentName] ?? 0;
                              return Card(
                                child: ListTile(
                                  title: Text(item.studentName,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('الشعبة: ${item.gradeClass}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Chip(
                                        label: Text('المجموع: $totalTimes'),
                                        backgroundColor: totalTimes >= 4
                                            ? Colors.red[100]
                                            : Colors.teal[50],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteRecord(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  )
                ],
              ),
            ),

            // الشاشة الثانية: السجل التراكمي وتنبيه الـ 4 غيابات/تأخيرات
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.amber[100],
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.brown),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الطالبات المكتوبة باللون الأحمر تجاوزن 4 تأخيرات وتتطلب استدعاء ولي أمر.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: tardinessCounts.isEmpty
                        ? const Center(child: Text('السجل التراكمي فارغ حالياً'))
                        : ListView(
                            children: tardinessCounts.entries.map((entry) {
                              final name = entry.key;
                              final count = entry.value;
                              final isCritical = count >= 4;

                              return Card(
                                color: isCritical ? Colors.red[50] : Colors.white,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCritical ? Colors.red : Colors.teal,
                                    child: Text('$count',
                                        style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCritical ? Colors.red[900] : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isCritical
                                        ? '⚠️ يتوجب استدعاء ولي الأمر فوراً'
                                        : 'تأخير منتظم',
                                    style: TextStyle(
                                        color: isCritical ? Colors.red : Colors.grey[700]),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
