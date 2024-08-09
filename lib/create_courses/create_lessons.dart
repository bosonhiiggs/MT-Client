import 'package:flutter/material.dart';
import 'create_lessons_filling.dart';
import 'create_course_moduels.dart'; // Убедитесь, что импортируете правильный файл

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
  late String _moduleName;
  late TextEditingController _moduleNameController;
  List<String> _lessons = [];

  @override
  void initState() {
    super.initState();
    _moduleName = widget.moduleName;
    _moduleNameController = TextEditingController(text: _moduleName);
    _lessons.add('1. Новый урок');
  }

  @override
  void dispose() {
    _moduleNameController.dispose();
    super.dispose();
  }

  void _reindexLessons(int index) {
    setState(() {
      _lessons.removeAt(index);
      for (int i = index; i < _lessons.length; i++) {
        _lessons[i] = '${i + 1}. ${_lessons[i].split('.').last}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание уроков'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
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
                    child: TextField(
                      controller: _moduleNameController,
                      decoration: InputDecoration(
                        hintText: 'Название модуля',
                        labelStyle: TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                      onChanged: (value) {
                        setState(() {
                          _moduleName = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  for (int index = 0; index < _lessons.length; index++) ... [
                    SizedBox(height: 4),
                    Dismissible(
                      key: Key(_lessons[index]),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: AlignmentDirectional.centerStart,
                        padding: EdgeInsets.only(left: 16.0),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.delete,
                              color: Color(0xFFF48FB1),
                              size: 24,
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width - 120),
                          ],
                        ),
                      ),
                      onDismissed: (direction) {
                        _reindexLessons(index);
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              children: [
                                Text('${_lessons[index].split('.').first}. '),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _lessons[index].split('.').last,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFFF48FB1),
                            shape: StadiumBorder(),
                          ),
                          onPressed: () async {
                            final lessonIndex = int.parse(_lessons[index].split('.').first);
                            final lessonName = _lessons[index].split('.').last;

                            final updatedLessonData = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateLessonPage2(
                                  courseName: widget.courseName,
                                  courseDescription: widget.courseDescription,
                                  courseAbout: widget.courseAbout,
                                  moduleIndex: widget.moduleIndex,
                                  moduleName: widget.moduleName,
                                  lessonIndex: lessonIndex,
                                  lessonName: lessonName,
                                ),
                              ),
                            ) as LessonData?;

                            if (updatedLessonData != null) {
                              setState(() {
                                _lessons[index] = '$lessonIndex. ${updatedLessonData.lessonName}';
                                // Store the rest of the data in the state or a variable
                                // For example:
                                // _videoPath = updatedLessonData.videoPath;
                                // _taskText = updatedLessonData.taskText;
                                // ... and so on
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        child: Text('Добавить урок'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFFF48FB1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          minimumSize: Size(150, 50), // Adjusted size
                        ),
                        onPressed: () {
                          setState(() {
                            _lessons.add('${_lessons.length + 1}. Новый урок');
                          });
                        },
                      ),
                      ElevatedButton(
                        child: Text('Сохранить'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFFF48FB1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          minimumSize: Size(150, 50), // Adjusted size
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateCoursePage3(
                                courseName: widget.courseName,
                                courseDescription: widget.courseDescription,
                                courseAbout: widget.courseAbout, coursePrice: '',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
