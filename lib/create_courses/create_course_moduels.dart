import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'create_lessons.dart';

class CreateCoursePage3 extends StatefulWidget {
  final String courseDescription;
  final String courseAbout;
  final String courseName;
  final String? courseImagePath;
  final String coursePrice;

  CreateCoursePage3({
    required this.courseDescription,
    required this.courseAbout,
    required this.courseName,
    this.courseImagePath,  // Сделаем этот параметр необязательным
    this.coursePrice = '0',
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchModules(); // Обновляем данные при изменении зависимостей
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionId = prefs.getString('sessionid');
      _csrfToken = prefs.getString('csrftoken');
      _courseSlug = prefs.getString('courseSlug');
    });

    if (_courseSlug != null) {
      _fetchModules(); // Обновление модуля после загрузки предпочтений
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('Decoded data: $data');
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('Decoded data: $data');
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
    await _fetchModules(); // Обновляем модули при потягивании вниз
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
    // Implement save logic here if needed
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
                      // child: widget.courseImagePath != null
                      //     ? ClipRRect(
                      //   borderRadius: BorderRadius.circular(10),
                      //   child: Image.network(
                      //     widget.courseImagePath!,
                      //     fit: BoxFit.cover,
                      //   ),
                      // )
                      //     : Center(
                      //   child: Icon(
                      //     Icons.photo,
                      //     color: Colors.white,
                      //     size: 80,
                      //   ),
                      // ),
                      child: widget.courseImagePath != null && widget.courseImagePath!.isNotEmpty
                          ? widget.courseImagePath!.startsWith('http')
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.courseImagePath!,
                          fit: BoxFit.cover,
                        ),
                      )
                          : widget.courseImagePath!.startsWith('data:image')
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(widget.courseImagePath!.split(',').last),
                          fit: BoxFit.cover,
                        ),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(widget.courseImagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                          : Center(
                        child: Icon(
                          Icons.photo,  // Иконка-заполнитель, если логотипа нет
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
                                    color: Colors.white, // Цвет текста на кнопке
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
                                        moduleId: module['id'],
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
                          color: Colors.black, // Цвет текста в поле ввода
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
                                color: Colors.white, // Цвет текста на кнопке
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF48FB1),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _onSavePressed,
                            child: Text(
                              'Сохранить',
                              style: TextStyle(
                                color: Colors.white, // Цвет текста на кнопке
                              ),
                            ),
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
      ),
    );
  }
}
