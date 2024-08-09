import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'create_course_moduels.dart';

class CreateCoursePage2 extends StatefulWidget {
  @override
  _CreateCoursePageState2 createState() => _CreateCoursePageState2();
}

class _CreateCoursePageState2 extends State<CreateCoursePage2> {
  final _formKey = GlobalKey<FormState>();

  String _courseName = '';
  String _courseDescription = '';
  String _courseAbout = '';
  File? _courseImage;

  String? _courseSlug;  // Переменная для хранения slug

  final ImagePicker _picker = ImagePicker();

  // Функция для выбора изображения
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _courseImage = File(pickedFile.path);
      });
    }
  }

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
        final responseData = jsonDecode(response.body);
        _courseSlug = responseData['slug'];  // Извлечение slug

        // Сохранение slug в кэш
        await prefs.setString('courseSlug', _courseSlug!);

        // Вывод slug в терминал
        print('Slug: $_courseSlug');

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
              courseImagePath: _courseImage?.path,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
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
                      child: _courseImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _courseImage!,
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
                    Positioned(
                      top: 5, // Уменьшаем расстояние сверху
                      right: 10,
                      child: IconButton(
                        icon: Icon(
                          Icons.add_a_photo,
                          color: Colors.white,
                          size: 24, // Уменьшаем размер иконки
                        ),
                        onPressed: _pickImage,
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
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Название курса',
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null, // Поле расширяется по мере ввода текста
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
                                  SizedBox(height: 10),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Чему учит курс',
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null, // Поле расширяется по мере ввода текста
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
                                  SizedBox(height: 10),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'О курсе',
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null, // Поле расширяется по мере ввода текста
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      child: Text('Создать курс'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFFF48FB1),
                        shape: StadiumBorder(),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _sendCourseData(); // Отправляем данные на сервер
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
