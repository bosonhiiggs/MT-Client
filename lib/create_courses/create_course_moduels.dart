import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'create_lessons.dart';
import 'create_course_naming.dart';

class CreateCoursePage3 extends StatefulWidget {
  final String courseName;
  final String courseDescription;
  final String courseAbout;
  final String? courseImagePath;

  CreateCoursePage3({
    required this.courseName,
    required this.courseDescription,
    required this.courseAbout,
    this.courseImagePath,
  });

  @override
  _CreateCoursePage3State createState() => _CreateCoursePage3State();
}

class _CreateCoursePage3State extends State<CreateCoursePage3> {
  final _formKey = GlobalKey<FormState>();

  String? _sessionId;
  String? _csrfToken;
  String? _courseSlug;
  String _introduction = '';
  List<String> _lessons = [];
  int _moduleIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Загружаем сессионный ID, токен и slug
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('sessionid');
      _csrfToken = prefs.getString('csrftoken');
      _courseSlug = prefs.getString('courseSlug');
    });
  }

  Future<void> _createModule(String moduleTitle) async {
    if (_courseSlug == null) return;

    final url = 'http://80.90.187.60:8001/api/mycreations/create/$_courseSlug/modules/';
    print('Отправляемый URL: $url');

    // Подготавливаем данные в формате JSON-объекта
    final msgJson = json.encode({
      'title': moduleTitle,
    });
    print('Отправляемое тело: $msgJson');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
        'X-CSRFToken': _csrfToken!,
      },
      body: msgJson,
    );

    // Декодируем ответ и обрабатываем ошибки
    final rawData = utf8.decode(response.bodyBytes);
    print('Raw data: $rawData');

    try {
      final data = json.decode(rawData);
      print('Decoded data: $data');
    } catch (e) {
      print('Ошибка при декодировании JSON: $e');
    }

    if (response.statusCode == 200) {
      print('Модуль успешно создан');
    } else {
      print('Ошибка при создании модуля: ${response.statusCode}');
      print('Тело ответа: $rawData');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание модуля'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 280, // Увеличиваем высоту контейнера
                    decoration: BoxDecoration(
                      color: Color(0xFFF596B9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: widget.courseImagePath != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(widget.courseImagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                        : Center(
                      child: Icon(
                        Icons.photo,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: double.infinity,
                        height: 200, // Уменьшаем высоту плашки
                        margin: EdgeInsets.all(20), // Добавляем отступы от границ картинки
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5), // Полупрозрачный фон
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.courseName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Чему учит курс',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  widget.courseDescription,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'О курсе',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  widget.courseAbout,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_introduction.isNotEmpty)
                      Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          color: Colors.white,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.delete, color: Color(0xFFF48FB1)),
                              SizedBox(width: MediaQuery.of(context).size.width - 120),
                              Icon(Icons.delete, color: Color(0xFFF48FB1)),
                            ],
                          ),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            _introduction = '';
                          });
                        },
                        child: ElevatedButton(
                          child: Text('Модуль 1'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFFF48FB1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          onPressed: () async {
                            final List<String>? lessons = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateLessonPage(
                                  courseName: widget.courseName,
                                  courseDescription: widget.courseDescription,
                                  courseAbout: widget.courseAbout,
                                  moduleIndex: 0,
                                  moduleName: _lessons[0],
                                ),
                              ),
                            );
                            if (lessons != null) {
                              setState(() {
                                _lessons[0] = lessons[0];
                                _lessons.addAll(lessons.sublist(1));
                              });
                            }
                          },
                        ),
                      ),
                    ..._lessons.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      return Dismissible(
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
                        onDismissed: (direction) {
                          setState(() {
                            _lessons.removeAt(index - 1);
                          });
                        },
                        child: Column(
                          children: [
                            ElevatedButton(
                              child: Text('$index. ${entry.value}'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFFF48FB1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                minimumSize: Size(double.infinity, 50),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateLessonPage(
                                      courseName: widget.courseName,
                                      courseDescription: widget.courseDescription,
                                      courseAbout: widget.courseAbout,
                                      moduleIndex: 0,
                                      moduleName: _lessons[0],
                                    ),
                                  ),
                                ).then((value) {
                                  setState(() {
                                    _lessons = value[1];
                                    _introduction = 'Модуль $index: ${value[0]}';
                                  });
                                });
                              },
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      );
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          child: Text('Добавить модуль'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFFF48FB1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _lessons.add('Новый модуль');
                            });
                            _createModule('Новый модуль'); // Отправка запроса на сервер
                          },
                        ),
                        ElevatedButton(
                          child: Text('Сохранить'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFFF48FB1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateCoursePage2(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
