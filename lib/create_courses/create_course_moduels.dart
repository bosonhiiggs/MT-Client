import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main_pages/my_creations_page.dart';
import 'create_lessons.dart';

class CreateCoursePage3 extends StatefulWidget {
  final String courseName;
  final String courseDescription;
  final String courseAbout;
  final String? courseImagePath;

  CreateCoursePage3({
    required this.courseName,
    required this.courseDescription,
    required this.courseAbout,
    this.courseImagePath, required String coursePrice,
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
  List<Map<String, dynamic>> _modules = [];
  TextEditingController _moduleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _moduleController.text = 'Новый модуль';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchModules();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('sessionid');
      _csrfToken = prefs.getString('csrftoken');
      _courseSlug = prefs.getString('courseSlug');
    });

    if (_courseSlug != null) {
      _fetchModules();
    }
  }

  Future<void> _fetchModules() async {
    if (_courseSlug == null) return;

    final url = 'http://80.90.187.60:8001/api/mycreations/create/$_courseSlug/modules/';
    print('Fetching modules from: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken',
          'X-CSRFToken': _csrfToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> results = data['results'] ?? [];
        setState(() {
          _modules = results.map((item) {
            return {
              'id': item['id'].toString(),
              'title': item['title'],
            };
          }).toList();
        });
        print('Modules fetched successfully: $_modules');
      } else {
        print('Failed to fetch modules: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching modules: $e');
    }
  }

  Future<void> _createModule(String moduleTitle) async {
    if (_courseSlug == null) return;

    final url = 'http://80.90.187.60:8001/api/mycreations/create/$_courseSlug/modules/';
    print('Creating module at: $url');

    final msgJson = json.encode({
      'title': moduleTitle,
    });

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

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final newModuleId = data['id'].toString();

        setState(() {
          _modules.add({'id': newModuleId, 'title': moduleTitle});
        });
        print('Module created successfully with ID: $newModuleId');
      } else {
        print('Failed to create module: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error creating module: $e');
    }
  }

  Future<void> _addCourse(
      String courseName,
      String courseDescription,
      String courseAbout,
      String? courseImagePath,
      ) async {
    if (_sessionId == null || _csrfToken == null) return;

    final url = 'http://80.90.187.60:8001/api/mycreations/create/';
    print('Отправляемый URL: $url');

    final msgJson = json.encode({
      'name': courseName,
      'description': courseDescription,
      'about': courseAbout,
      'image': courseImagePath,
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

    try {
      final data = json.decode(rawData);
      print('Decoded data: $data');
    } catch (e) {
      print('Ошибка при декодировании JSON: $e');
    }

    if (response.statusCode == 200) {
      print('Курс успешно создан');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyCreationsScreen(
            courseName: courseName,
            courseDescription: courseDescription,
            courseAbout: courseAbout,
            courseImagePath: courseImagePath,
          ),
        ),
      );
    } else {
      print('Ошибка при создании курса: ${response.statusCode}');
      print('Тело ответа: $rawData');
    }
  }

  Future<void> _deleteModule(String moduleId) async {
    if (_courseSlug == null || moduleId.isEmpty) return;

    final url = 'http://80.90.187.60:8001/api/mycreations/create/$_courseSlug/modules/$moduleId';
    print('Deleting module at: $url');

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
        setState(() {
          _modules.removeWhere((module) => module['id'] == moduleId);
        });
        print('Module deleted successfully');
      } else {
        print('Failed to delete module: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error deleting module: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchModules();
  }

  void _onAddModulePressed() {
    final moduleTitle = _moduleController.text.trim();
    if (moduleTitle.isNotEmpty) {
      _createModule(moduleTitle);
      _moduleController.clear();
      _moduleController.text = 'Новый модуль';
    }
  }

  void _onSavePressed() {
    print('Changes saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание модуля'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
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
                                    widget.courseName,
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
                                      fontSize: 16,
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
                                    moduleName: _lessons[0], courseSlug: '', moduleId: '',
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
                            print('Deleting module: ${module['id']}');
                            await _deleteModule(module['id']);
                          },
                          child: Column(
                            children: [
                              ElevatedButton(
                                child: Text(
                                  '$index. ${module['title']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
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
                                        courseSlug: _courseSlug!,
                                        courseDescription: widget.courseDescription,
                                        courseAbout: widget.courseAbout,
                                        moduleIndex: entry.key,
                                        moduleName: module['title'],
                                        moduleId: module['id'], courseName: '',
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value != null) {
                                      setState(() {
                                        _modules[entry.key]['title'] = value[0];
                                      });
                                    }
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
                        style: TextStyle(
                          color: Colors.black,
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
                            child: Text(
                              'Добавить модуль',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF48FB1),
                            ),
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
                            onPressed: () async {
                              await _addCourse(
                                widget.courseName,
                                widget.courseDescription,
                                widget.courseAbout,
                                widget.courseImagePath,
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
      ),
    );
  }
}
