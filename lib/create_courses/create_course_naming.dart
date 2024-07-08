import 'package:flutter/material.dart';
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
                maxLines: null, // Позволяет тексту автоматически переноситься на новую строку
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
                maxLines: null, // Позволяет тексту автоматически переноситься на новую строку
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
                maxLines: null, // Позволяет тексту автоматически переноситься на новую строку
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
