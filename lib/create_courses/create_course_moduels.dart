import 'dart:convert';
import 'dart:io';
import 'package:client/create_courses/create_course_naming.dart';
import 'package:client/main_pages/my_creations_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_lessons.dart';
import 'create_course_naming.dart';

class CreateCoursePage3 extends StatefulWidget {
  final String courseDescription;
  final String courseAbout;
  final String courseName; // Добавляем параметр для названия курса
  final String? courseImagePath;

  CreateCoursePage3({
    required this.courseDescription,
    required this.courseAbout,
    required this.courseName, // Обновляем конструктор для включения названия курса
    this.courseImagePath,
    required String coursePrice,
  });

  @override
  _CreateCoursePage3State createState() => _CreateCoursePage3State();
}

class _CreateCoursePage3State extends State<CreateCoursePage3> {
  final _formKey = GlobalKey<FormState>();

  String? _sessionId;
  String? _csrfToken;
  String? _courseSlug;
  List<Map<String, dynamic>> _modules = [];
  TextEditingController _moduleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _moduleController.text = 'Новый модуль'; // Устанавливаем начальный текст
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('sessionid');
      _csrfToken = prefs.getString('csrftoken');
      _courseSlug = prefs.getString('courseSlug');
    });

    _fetchModules();
  }

  Future<void> _fetchModules() async {
    if (_courseSlug == null) return;

    final url = 'http://80.90.187.60:8001/api/mycreations/create/$_courseSlug/modules/';
    print('Отправляемый URL для получения модулей: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
        'X-CSRFToken': _csrfToken!,
      },
    );

    final rawData = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      try {
        final data = json.decode(rawData);
        List<dynamic> results = data['results'];
        List<Map<String, dynamic>> modules = results.map((item) {
          return {
            'id': item['id'].toString(),
            'title': item['title'],
          };
        }).toList();
        setState(() {
          _modules = modules;
        });
        print('Модули успешно загружены: $_modules');
      } catch (e) {
        print('Ошибка при декодировании JSON: $e');
      }
    } else {
      print('Ошибка при получении модулей: ${response.statusCode}');
      print('Тело ответа: $rawData');
    }
  }

  Future<void> _saveModuleId(String moduleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('moduleId', moduleId);
  }

  Future<void> _createModule(String moduleTitle) async {
    if (_courseSlug == null) return;

    final url = 'http://80.90.187.60:8001/api/mycreations/create/$_courseSlug/modules/';
    print('Отправляемый URL для создания модуля: $url');

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

    final rawData = utf8.decode(response.bodyBytes);
    print('Raw data: $rawData');

    if (response.statusCode == 201) {
      try {
        final data = json.decode(rawData);
        print('Decoded data: $data');
        final newModuleId = data['id'].toString();
        await _saveModuleId(newModuleId);

        // Обновите список модулей, добавив новый модуль
        setState(() {
          _modules.add({'id': newModuleId, 'title': moduleTitle});
        });

        print('Модуль успешно создан с ID: $newModuleId');
      } catch (e) {
        print('Ошибка при декодировании JSON: $e');
      }
    } else {
      print('Ошибка при создании модуля: ${response.statusCode}');
      print('Тело ответа: $rawData');
    }
  }

  Future<void> _deleteModule(String moduleId) async {
    if (_courseSlug == null || moduleId.isEmpty) return;

    final url = 'http://80.90.187.60:8001/api/mycreations/create/$_courseSlug/modules/$moduleId';
    print('Отправляемый URL для удаления: $url');

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
        'X-CSRFToken': _csrfToken!,
      },
    );

    final rawData = utf8.decode(response.bodyBytes);

    print('Статус код ответа: ${response.statusCode}');
    print('Тело ответа: $rawData');

    if (response.statusCode == 204) {
      setState(() {
        _modules.removeWhere((module) => module['id'] == moduleId);
      });
      print('Модуль успешно удален');
    } else {
      print('Ошибка при удалении модуля: ${response.statusCode}');
      print('Тело ответа: $rawData');
    }
  }

  void _onAddModulePressed() {
    _createModule(_moduleController.text);
    _moduleController.clear();
    _moduleController.text = 'Новый модуль';
  }

  void _onSavePressed() {
    // Реализуйте логику сохранения изменений здесь, если необходимо
    print('Изменения сохранены');
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
                    height: 280,
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
                        height: 200,
                        margin: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.courseName, // Добавляем название курса
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  widget.courseDescription,
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
                    ..._modules.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      final module = entry.value;
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
                        onDismissed: (direction) async {
                          print('Модуль для удаления: ${module['id']}');
                          await _deleteModule(module['id']);
                        },
                        child: Column(
                          children: [
                            ElevatedButton(
                              child: Text('$index. ${module['title']}'),
                              style: ElevatedButton.styleFrom(
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
                                      courseSlug: _courseSlug!, // Передаем _courseSlug
                                      courseDescription: widget.courseDescription,
                                      courseAbout: widget.courseAbout,
                                      moduleIndex: entry.key,
                                      moduleName: module['title'],
                                      moduleId: module['id'],

                                    ),
                                  ),
                                ).then((value) {
                                  setState(() {
                                    if (value != null) {
                                      _modules[entry.key]['title'] = value[0];
                                    }
                                  });
                                });
                              },
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _moduleController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Название нового модуля',
                      ),
                      onFieldSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _createModule(value);
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _onAddModulePressed,
                          child: Text('Добавить модуль'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF48FB1),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _onSavePressed,
                          child: Text('Сохранить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF48FB1),
                          ),
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
