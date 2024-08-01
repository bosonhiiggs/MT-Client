import 'dart:convert';
import 'package:flutter/material.dart';
import 'create_course_moduels.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateCoursePage2 extends StatefulWidget {
  @override
  _CreateCoursePageState2 createState() => _CreateCoursePageState2();
}

class _CreateCoursePageState2 extends State<CreateCoursePage2> {
  final _formKey = GlobalKey<FormState>();

  String _courseName = '';
  String _courseDescription = '';
  String _courseAbout = '';

  // Функция для отправки данных на сервер
  Future<void> _sendCourseData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionid = prefs.getString('sessionid');
      String? csrfToken = prefs.getString('csrftoken');

      if (sessionid == null || csrfToken == null) {
        throw Exception('Session ID или CSRF token отсутствуют');
      }

      final url = 'http://80.90.187.60:8001/api/mycreations/create/free/';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sessionid=$sessionid; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken,
        },
        body: jsonEncode({
          'title': _courseName,
          'target_description': _courseDescription,
          'description': _courseAbout,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        // Успешно создано
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Курс успешно создан!')),
        );
        // Перейдите на следующую страницу, если это необходимо
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateCoursePage3(
              courseName: _courseName,
              courseDescription: _courseDescription,
              courseAbout: _courseAbout,
            ),
          ),
        );
      } else {
        // Ошибка создания курса
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания курса. Попробуйте снова.')),
        );
      }
    } catch (e) {
      print('Произошла ошибка: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке данных. Попробуйте снова.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создать курс'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Название курса',
                ),
                maxLines: null,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Пожалуйста, введите название курса';
                  }
                  return null;
                },
                onSaved: (value) {
                  _courseName = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Чему учит курс',
                ),
                maxLines: null,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Пожалуйста, введите описание чему учит курс';
                  }
                  return null;
                },
                onSaved: (value) {
                  _courseDescription = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'О курсе',
                ),
                maxLines: null,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Пожалуйста, введите описание курса';
                  }
                  return null;
                },
                onSaved: (value) {
                  _courseAbout = value!;
                },
              ),
              ElevatedButton(
                child: Text('Создать курс'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _sendCourseData(); // Отправляем данные на сервер
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
