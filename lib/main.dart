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
      title: 'Timely',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'JO'),
      supportedLocales: const [Locale('ar', 'JO')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        // خلفية ناعمة جداً بدرجة زهري ناصع وهادئ
        scaffoldBackgroundColor: const Color(0xFFFBF7F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E795D), // أخضر مريمي هادئ
          primary: const Color(0xFF4E795D),
          secondary: const Color(0xFFD48B97), // زهري وردي ناعم
          surface: const Color(0xFFFFFFFF),
        ),
        fontFamily: 'Roboto',
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
  String teacherName = "مروة سكجي";
  
  List<LateRecord> allRecords = [];
  final _nameController = TextEditingController();
  
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
        const SnackBar(
          content: Text('يرجى إدخال اسم الطالبة واختيار الشعبة'),
          backgroundColor: Color(0xFF4E795D),
        ),
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
          backgroundColor: const Color(0xFF4E795D), // أخضر مريمي أنيق
          elevation: 2,
          toolbarHeight: 125,
          title: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance, color: Color(0xFFF3E5DC), size: 22),
                  SizedBox(width: 8),
                  Text('وزارة التربية والتعليم - المملكة الأردنية الهاشمية',
                      style: TextStyle(fontSize: 12, color: Color(0xFFE8F0E9))),
                ],
              ),
              const SizedBox(height: 6),
              Text(schoolName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text('سجل التأخير اليومي | مسؤول اللجان: المعلمة الفاضلة ($teacherName)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFF9D6DC))), // لمسة زهري ناعمة
            ],
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFFF4B2BA), // مؤشر التبويب بزهري ناعم
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFCDE0D2),
            tabs: [
              Tab(icon: Icon(Icons.edit_calendar), text: "التسجيل اليومي"),
              Tab(icon: Icon(Icons.warning_amber_rounded), text: "السجل التراكمي والتنبيهات"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // الشاشة الأولى: التسجيل اليومي
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFEAE0E2)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month, color: Color(0xFF4E795D)),
                      title: Text('التاريخ المحدد: $formattedSelectedDate',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Color(0xFF334237))),
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
                        child: const Text('تغيير التاريخ',
                            style: TextStyle(color: Color(0xFFD48B97), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFEAE0E2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'اسم الطالبة الثلاثي/الرباعي',
                              labelStyle: const TextStyle(color: Color(0xFF6B7C70)),
                              filled: true,
                              fillColor: const Color(0xFFF7F2F3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.person_add, color: Color(0xFF4E795D)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedClass,
                            decoration: InputDecoration(
                              labelText: 'الصف والشعبة',
                              labelStyle: const TextStyle(color: Color(0xFF6B7C70)),
                              filled: true,
                              fillColor: const Color(0xFFF7F2F3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.class_, color: Color(0xFF4E795D)),
                            ),
                            items: classesList.map((String c) {
                              return DropdownMenuItem<String>(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) => setState(() => selectedClass = val),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD48B97), // زر باللون الزهري الوردي
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _addRecord,
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('تسجيل التأخير اليوم',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('قائمة التأخير لهذا اليوم:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF334237))),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: todayRecords.isEmpty
                        ? const Center(
                            child: Text('لا يوجد تسجيلات لهذا اليوم',
                                style: TextStyle(color: Color(0xFF9EA3A0))))
                        : ListView.builder(
                            itemCount: todayRecords.length,
                            itemBuilder: (context, index) {
                              final item = todayRecords[index];
                              int totalTimes = tardinessCounts[item.studentName] ?? 0;
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(item.studentName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334237))),
                                  subtitle: Text('الشعبة: ${item.gradeClass}',
                                      style: const TextStyle(color: Color(0xFF6B7C70))),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Chip(
                                        label: Text('المجموع: $totalTimes'),
                                        backgroundColor: totalTimes >= 4
                                            ? const Color(0xFFFADBD8)
                                            : const Color(0xFFE8F0E9),
                                        labelStyle: TextStyle(
                                          color: totalTimes >= 4 ? Colors.red[900] : const Color(0xFF334237),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFC0392B)),
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

            // الشاشة الثانية: السجل التراكمي
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFADBD8), // تنبيه بالزهري الفاتح
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الطالبات المكتوبة باللون الأحمر تجاوزن 4 تأخيرات وتتطلب استدعاء ولي أمر.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF78281F), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: tardinessCounts.isEmpty
                        ? const Center(
                            child: Text('السجل التراكمي فارغ حالياً',
                                style: TextStyle(color: Color(0xFF9EA3A0))))
                        : ListView(
                            children: tardinessCounts.entries.map((entry) {
                              final name = entry.key;
                              final count = entry.value;
                              final isCritical = count >= 4;

                              return Card(
                                color: isCritical ? const Color(0xFFFDEDEC) : Colors.white,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        isCritical ? const Color(0xFFE74C3C) : const Color(0xFF4E795D),
                                    child: Text('$count',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCritical ? const Color(0xFF78281F) : const Color(0xFF334237),
                                    ),
                                  ),
                                  subtitle: Text(
                                    isCritical ? '⚠️ يتوجب استدعاء ولي الأمر فوراً' : 'تأخير اعتيادي',
                                    style: TextStyle(
                                        color: isCritical ? const Color(0xFFC0392B) : const Color(0xFF6B7C70)),
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
