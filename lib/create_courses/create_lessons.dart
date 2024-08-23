import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Убедитесь, что этот импорт правильный
import 'create_course_moduels.dart';

class CreateLessonPage extends StatefulWidget {
  final String courseSlug;
  final String courseDescription;
  final String courseAbout;
  final int moduleIndex;
  final String moduleName;
  final String moduleId;
  final String? courseImagePath; // Сделайте параметр необязательным

  CreateLessonPage({
    required this.courseSlug,
    required this.courseDescription,
    required this.courseAbout,
    required this.moduleIndex,
    required this.moduleName,
    required this.moduleId,
    this.courseImagePath, // Добавьте этот параметр
  });

  @override
  _CreateLessonPageState createState() => _CreateLessonPageState();
}

class _CreateLessonPageState extends State<CreateLessonPage> {
  late String _moduleName;
  late TextEditingController _moduleNameController;
  List<Map<String, String>> _lessons = []; // Changed to hold a map with ID and title

  String? _sessionId;
  String? _csrfToken;

  @override
  void initState() {
    super.initState();
    _moduleName = widget.moduleName;
    _moduleNameController = TextEditingController(text: _moduleName);
    _loadPreferences();
    _loadLessons(); // Load lessons from server or other source
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('sessionid');
      _csrfToken = prefs.getString('csrftoken');
    });
  }

  Future<void> _loadLessons() async {
    // Load lessons from your server
    // Dummy data
    setState(() {
      _lessons = [
        {'id': '1', 'title': 'Новый урок'},
      ];
    });
  }

  Future<void> _updateModuleTitle(String newTitle) async {
    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}';
    final msgJson = json.encode({'title': newTitle});

    print('Updating module title with URL: $url');
    print('Request body: $msgJson');

    final response = await http.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
        'X-CSRFToken': _csrfToken!,
      },
      body: msgJson,
    );

    final rawData = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) {
      print('Module title successfully updated');
    } else {
      print('Error updating module title: ${response.statusCode}');
      print('Response body: $rawData');
    }
  }

  Future<void> _saveLessonId(String lessonId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lessonId', lessonId);
  }

  Future<void> _createLesson(String lessonTitle) async {
    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}';
    final msgJson = json.encode({'title': lessonTitle});

    print('Creating lesson with URL: $url');
    print('Request body: $msgJson');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
        'X-CSRFToken': _csrfToken!,
      },
      body: msgJson,
    );

    final rawData = utf8.decode(response.bodyBytes);
    print('Raw response data: $rawData');

    if (response.statusCode == 201) {
      try {
        final data = json.decode(rawData);
        final lessonId = data['id'].toString(); // Получаем ID урока из ответа
        print('Lesson successfully created with ID: $lessonId');
        await _saveLessonId(lessonId); // Сохраняем ID урока

        setState(() {
          _lessons.add({'id': lessonId, 'title': lessonTitle});
        });
      } catch (e) {
        print('Error decoding JSON: $e');
      }
    } else {
      print('Error creating lesson: ${response.statusCode}');
      print('Response body: $rawData');
    }
  }

  Future<bool> _deleteLesson(String lessonId, int index) async {
    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}/$lessonId/';

    print('Deleting lesson with URL: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
        'X-CSRFToken': _csrfToken!,
      },
    );

    if (response.statusCode == 204) {
      print('Lesson successfully deleted');
      return true;
    } else {
      print('Error deleting lesson: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${utf8.decode(response.bodyBytes)}');
      return false;
    }
  }

  Future<String?> _showAddLessonDialog(BuildContext context) async {
    String? lessonTitle;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Введите название урока'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Название урока',
            ),
            onChanged: (value) {
              lessonTitle = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(lessonTitle);
              },
              child: Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _moduleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание уроков'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1), // Цвет AppBar
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Color(0xFFF48FB1), // Цвет контейнера для модуля
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Название модуля',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _moduleNameController,
                      decoration: InputDecoration(
                        hintText: 'Введите название модуля',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                      onChanged: (value) {
                        setState(() {
                          _moduleName = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_moduleName.isNotEmpty) {
                          await _updateModuleTitle(_moduleName);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateCoursePage3(
                                courseDescription: widget.courseDescription,
                                courseAbout: widget.courseAbout,
                                courseName: _moduleName,
                                courseImagePath: widget.courseImagePath,
                                // Здесь можно изменить по необходимости
                              ),
                            ),
                          );
                        }
                      },
                      child: Text('Сохранить изменения'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF48FB1), // Цвет кнопки
                        foregroundColor: Colors.white, // Цвет текста на кнопке
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Уроки в модуле',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _lessons.length,
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];
                  return Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Color(0xFFF48FB1), // Цвет фона при свайпе
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) async {
                      final deleted = await _deleteLesson(lesson['id']!, index);
                      if (deleted) {
                        setState(() {
                          _lessons.removeAt(index);
                        });
                      }
                    },
                    child: ListTile(
                      title: Text(lesson['title'] ?? ''),

                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final lessonTitle = await _showAddLessonDialog(context);
                  if (lessonTitle != null && lessonTitle.isNotEmpty) {
                    await _createLesson(lessonTitle);
                  }
                },
                child: Text('Добавить урок'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF48FB1), // Цвет кнопки
                  foregroundColor: Colors.white, // Цвет текста на кнопке
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
