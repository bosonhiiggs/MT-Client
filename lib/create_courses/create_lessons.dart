import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_course_moduels.dart';
import 'create_lessons_filling.dart';

class CreateLessonPage extends StatefulWidget {
  final String courseSlug;
  final String courseDescription;
  final String courseAbout;
  final int moduleIndex;
  final String moduleName;
  final String moduleId;
  final String? courseImagePath;

  CreateLessonPage({
    required this.courseSlug,
    required this.courseDescription,
    required this.courseAbout,
    required this.moduleIndex,
    required this.moduleName,
    required this.moduleId,
    this.courseImagePath,
  });

  @override
  _CreateLessonPageState createState() => _CreateLessonPageState();
}

class _CreateLessonPageState extends State<CreateLessonPage> {
  late String _moduleName;
  late TextEditingController _moduleNameController;
  late TextEditingController _lessonTitleController;
  List<Map<String, dynamic>> _lessons = []; // Изменён тип переменной

  String? _sessionId;
  String? _csrfToken;

  @override
  void initState() {
    super.initState();
    _moduleName = widget.moduleName;
    _moduleNameController = TextEditingController(text: _moduleName);
    _lessonTitleController = TextEditingController();
    _loadPreferences();
    _loadLessons();
  }

  @override
  void dispose() {
    _moduleNameController.dispose();
    _lessonTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('sessionid');
      _csrfToken = prefs.getString('csrftoken');
    });

    // Вывод значений в терминал

  }

  Future<void> _loadLessons() async {
    SharedPreferences prefs_second = await SharedPreferences.getInstance();
    String? sessionId = prefs_second.getString('sessionid');
    String? csrfToken = prefs_second.getString('csrftoken');

    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}';

    print('Loading lessons with URL: $url');

    try {


      final headers = {
        'Content-Type': 'application/json',
      };

      print('Session ID: $_sessionId');
      print('CSRF Token: $_csrfToken');

      if (_sessionId != null && _csrfToken != null) {
        headers['Cookie'] = 'sessionid=$_sessionId; csrftoken=$_csrfToken';
        headers['X-CSRFToken'] = _csrfToken!;
        print('Session ID: $_sessionId');
        print('CSRF Token: $_csrfToken');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sessionid=$sessionId; csrftoken=$csrfToken',
          // 'X-CSRFToken': csrfToken,

        },
      );


      final rawData = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        print('Successfully loaded lessons');
        print('Response data: $rawData');

        final data = json.decode(rawData);
        setState(() {
          // Обрабатываем ответ от сервера
          final moduleData = data[0];
          final lessonsData = data[1];

          _moduleName = moduleData['module_title'] ?? '';
          _lessons = (lessonsData as List).map((lesson) {
            return {
              'id': lesson['id'].toString(),
              'title': lesson['title']
            };
          }).toList();
        });
      } else {
        print('Error loading lessons: ${response.statusCode}');
        print('Response body: $rawData');
      }
    } catch (e) {
      print('Error loading lessons: $e');
    }
  }

  Future<void> _updateModuleTitle(String newTitle) async {
    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}';
    final msgJson = json.encode({'title': newTitle});

    print('Updating module title with URL: $url');
    print('Request body: $msgJson');

    try {
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
    } catch (e) {
      print('Error updating module title: $e');
    }
  }

  Future<void> _saveLessonId(String lessonId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lessonId', lessonId);
  }

  Future<void> _createLesson(String lessonTitle) async {
    if (lessonTitle.isEmpty) {
      lessonTitle = 'Новый урок';
    }

    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}';
    final msgJson = json.encode({'title': lessonTitle});

    print('Creating lesson with URL: $url');
    print('Request body: $msgJson');

    try {
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
          final lessonId = data['id'].toString();
          print('Lesson successfully created with ID: $lessonId');
          await _saveLessonId(lessonId);

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
    } catch (e) {
      print('Error creating lesson: $e');
    }
  }

  Future<bool> _deleteLesson(String lessonId, int index) async {
    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}/$lessonId/';

    print('Deleting lesson with URL: $url');

    try {
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
    } catch (e) {
      print('Error deleting lesson: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание уроков'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
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
                  color: Color(0xFFF48FB1),
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
                                courseName: widget.courseSlug,
                                courseImagePath: widget.courseImagePath,
                              ),
                            ),
                          );
                        }
                      },
                      child: Text('Сохранить изменения'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF48FB1),
                        foregroundColor: Colors.white,
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
                  final lessonNumber = index + 1; // Индексы начинаются с 1

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Dismissible(
                      key: UniqueKey(),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        color: Colors.white,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.delete,
                          color: Color(0xFFF48FB1),
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.white,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.delete,
                          color: Color(0xFFF48FB1),
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
                      child: InkWell(
                        onTap: () {
                          // Переход на CreateLessonPage2 при нажатии на урок
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateLessonPage2(
                                courseSlug: widget.courseSlug,
                                courseDescription: widget.courseDescription,
                                courseAbout: widget.courseAbout,
                                moduleIndex: widget.moduleIndex,
                                moduleName: widget.moduleName,
                                lessonIndex: index, // Индекс урока
                                lessonName: lesson['title'] ?? '', // Название урока
                                moduleId: widget.moduleId,
                                lessonId: lesson['id'] ?? '', // Передайте ID урока
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF48FB1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Text(
                              '$lessonNumber. ${lesson['title'] ?? ''}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 16),
              TextFormField(
                controller: _lessonTitleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Название нового урока',
                ),
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final lessonTitle = _lessonTitleController.text;
                  // Если название урока пустое, используйте "Новый урок"
                  await _createLesson(lessonTitle);
                  _lessonTitleController.clear();
                },
                child: Text('Добавить урок'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF48FB1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
