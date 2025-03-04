import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'create_course_moduels.dart';

class PaidCoursePage extends StatefulWidget {
  @override
  _PaidCoursePage createState() => _PaidCoursePage();
}

class _PaidCoursePage extends State<PaidCoursePage> {
  final _formKey = GlobalKey<FormState>();

  String _courseName = '';
  String _courseDescription = '';
  String _courseAbout = '';
  String _coursePrice = '';
  File? _courseImage;

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

      final url = 'http://109.73.196.253:8001/api/mycreations/create/free/';

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
      request.headers['X-CSRFToken'] = csrfToken;

      request.fields['title'] = _courseName;
      request.fields['target_description'] = _courseDescription;
      request.fields['description'] = _courseAbout;
      request.fields['price'] = _coursePrice;

      if (_courseImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _courseImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      var response = await request.send();

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
              courseImagePath: _courseImage?.path,
              coursePrice: _coursePrice,
            ),
          ),
        );
      } else {
        // Ошибка создания курса
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания курса. Попробуйте снова.')),
        );
        // Выводим ответ от сервера для отладки
        var responseBody = await response.stream.bytesToString();
        print('Ответ от сервера: $responseBody');
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
                                    maxLines: 1, // Ограничиваем высоту поля ввода
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
                                    maxLines: 1, // Ограничиваем высоту поля ввода
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
                                    maxLines: 1, // Ограничиваем высоту поля ввода
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
                  children: [
                    SizedBox(
                      width: 200, // Задаем фиксированную ширину для поля ввода цены
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Цена курса',
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF48FB1), width: 2.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF48FB1), width: 2.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF48FB1), width: 2.0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        maxLines: 1, // Ограничиваем высоту поля ввода
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Пожалуйста, введите цену курса';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _coursePrice = value!;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
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
