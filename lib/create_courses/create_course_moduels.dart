import 'package:flutter/material.dart';
import 'create_lessons.dart';

class CreateCoursePage3 extends StatefulWidget {
  final String courseName;
  final String courseDescription;
  final String courseAbout;

  CreateCoursePage3({
    required this.courseName,
    required this.courseDescription,
    required this.courseAbout,
  });

  @override
  _CreateCoursePage3State createState() => _CreateCoursePage3State();
}

class _CreateCoursePage3State extends State<CreateCoursePage3> {
  final _formKey = GlobalKey<FormState>();

  String _introduction = '';
  List<String> _lessons = [];
  int _moduleIndex = 1;

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
              Container(
                width: 400, // Фиксированная ширина контейнера
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
                      widget.courseName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'О чем курс',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.courseDescription,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Чему учит курс',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.courseAbout,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
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
                      },
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
