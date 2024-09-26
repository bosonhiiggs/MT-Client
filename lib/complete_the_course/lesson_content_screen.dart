import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'course_details_screen.dart';
import 'package:http/http.dart' as http;

class LessonContentScreen extends StatefulWidget {
  final Lesson lesson;
  final String courseSlug;
  final int moduleId;
  final int lessonId;

  LessonContentScreen({required this.lesson,
    required this.courseSlug,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  _LessonContentScreenState createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  int _currentStep = 0;
  dynamic _lessonData;

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Загружаем данные при инициализации
  }

  Future<void> _loadPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');
      final Map<String, String> headers = {};

      if (sessionid != null && csrfToken != null) {
        headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
        headers['X-CSRFToken'] = csrfToken;
      }

      final url = 'http://80.90.187.60:8001/api/mycourses/${widget
          .courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/';
      final response = await http.get(
          Uri.parse(url),
          headers: headers
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = jsonDecode(rawData);
        // print('Decoded data: $data');
        setState(() {
          _lessonData = data;
        });
        print("Initial $_lessonData");

      } else {
        print('Cant load to lesson data. Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }
    } catch (e) {
      print('Error to process load lesson data: $e');
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
        actions: [
          Row(
            children: List.generate(4, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentStep == index ? Color(0xFFF48FB1) : Colors.grey,
                  border: Border.all(
                    color: Colors.black,
                    width: 2.0,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStepContent(),
          Spacer(), // Добавляем Spacer для перемещения кнопок вниз
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    if (_lessonData == null) {
      return Center(child: CircularProgressIndicator()); // Индикатор загрузки
    }

    final contents = _lessonData['contents'];

    for (var content in contents) {
      // print(content.runtimeType);
      // print(content);
      // print('');

      if (content.containsKey('text_content')) {
        print('text');
      }


    }

    switch (_currentStep) {
      case 0:
        return _buildVideoStep();
      case 1:
        return _buildTheoryStep();
      case 2:
        return _buildTestStep();
      case 3:
        return _buildHomeworkStep();
      default:
        return Container();
    }
  }

  Widget _buildVideoStep() {
    return Column(
      children: [
        AppBar(
          title: Text('Видео'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        // Здесь вы можете добавить виджет для отображения видео
        Text('Видео контент'),
      ],
    );
  }

  Widget _buildTheoryStep() {
    return Column(
      children: [
        AppBar(
          title: Text('Теория'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        // Здесь вы можете добавить виджет для отображения теории
        Text('Теоретический контент'),
      ],
    );
  }

  Widget _buildTestStep() {
    return Column(
      children: [
        AppBar(
          title: Text('Тест'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        // Здесь вы можете добавить виджет для отображения теста
        Text('Тестовый контент'),
      ],
    );
  }

  Widget _buildHomeworkStep() {
    return Column(
      children: [
        AppBar(
          title: Text('Домашнее задание'),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        // Здесь вы можете добавить виджет для отображения домашнего задания
        Text('Домашнее задание'),
        ElevatedButton(
          onPressed: () {
            // Логика для отправки домашнего задания
          },
          child: Text('Отправить домашнее задание'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFFF48FB1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep--;
              });
            },
            child: Text('Предыдущий этап'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFFF48FB1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        Spacer(), // Добавляем Spacer для создания пространства между кнопками
        if (_currentStep < 3)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep++;
              });
            },
            child: Text('Следующий этап'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFFF48FB1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        if (_currentStep == 3)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Закончить урок'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFFF48FB1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
      ],
    );
  }
}
