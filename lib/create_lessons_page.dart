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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
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
                        SizedBox(height: 8),
                        Text(
                          '${widget.moduleIndex + 1}. Модуль',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return Column(
                  children: [
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

                          onPressed: () {


                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
              childCount: _lessons.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                child: Text('Добавить урок'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFFF48FB1),
                  shape: StadiumBorder(),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  setState(() {
                    _lessons.add('${_lessons.length + 1}. Новый урок');
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}