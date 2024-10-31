import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AttendancePage(),
    );
  }
}

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Database? _database;
  List<Map<String, dynamic>> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'attendance.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE attendance(id INTEGER PRIMARY KEY, name TEXT, checked INTEGER)',
        );
      },
      version: 1,
    );
    _fetchAttendance();
  }

  Future<void> _addAttendance(String name, bool checked) async {
    await _database!.insert(
      'attendance',
      {'name': name, 'checked': checked ? 1 : 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    final List<Map<String, dynamic>> records = await _database!.query('attendance');
    setState(() {
      _attendanceRecords = records;
    });
  }

  Future<void> _toggleAttendance(String name) async {
    final record = _attendanceRecords.firstWhere((element) => element['name'] == name);
    final newCheckedStatus = record['checked'] == 1 ? 0 : 1;
    await _database!.update(
      'attendance',
      {'checked': newCheckedStatus},
      where: 'name = ?',
      whereArgs: [name],
    );
    _fetchAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance')),
      body: ListView.builder(
        itemCount: _attendanceRecords.length,
        itemBuilder: (context, index) {
          final record = _attendanceRecords[index];
          return ListTile(
            title: Text(record['name']),
            trailing: Switch(
              value: record['checked'] == 1,
              onChanged: (value) {
                _toggleAttendance(record['name']);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          String name = await _showAddDialog(context);
          _addAttendance(name, true);
        },
      ),
    );
  }

  Future<String> _showAddDialog(BuildContext context) async {
    String input = '';
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Name'),
          content: TextField(onChanged: (value) => input = value),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(''),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () => Navigator.of(context).pop(input),
            ),
          ],
        );
      },
    );
  }
}
