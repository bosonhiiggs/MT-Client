import 'package:flutter/material.dart';

class CreateLessonPage extends StatefulWidget {
  final String courseName;
  final String courseDescription;
  final String courseAbout;
  final int moduleIndex;
  final String moduleName;

  CreateLessonPage({
    required this.courseName,
    required this.courseDescription,
    required this.courseAbout,
    required this.moduleIndex,
    required this.moduleName,
  });

  @override
  _CreateLessonPageState createState() => _CreateLessonPageState();
}

class _CreateLessonPageState extends State<CreateLessonPage> {
  final _formKey = GlobalKey<FormState>();

  List<String> _lessons = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание урока'),
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
                  borderRadius: BorderRadius.circular(8.0),
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
                      widget.moduleName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Модуль ${widget.moduleIndex + 1}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: _lessons.isNotEmpty ? _lessons[0] : null,
                      decoration: InputDecoration(
                        labelText: 'Название урока',
                        labelStyle: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите название урока';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        setState(() {
                          _lessons[0] = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              if (_lessons.length > 1)
                Column(
                  children: List.generate(_lessons.length - 1, (index) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${index + 2}. ${_lessons[index + 1]}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () {
                                setState(() {
                                  _lessons.removeAt(index + 1);
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                    );
                  }),
                ),
              ElevatedButton(
                  child: Text('Добавить урок'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF48FB1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _lessons.add('');
                    });
                  }),
              SizedBox(height: 16),
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
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      Navigator.pop(context, _lessons);
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }
}