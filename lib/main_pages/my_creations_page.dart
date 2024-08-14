import 'package:flutter/material.dart';
import '../create_courses/create_course_naming.dart';
import 'profile_page.dart';
import 'music_courses_page.dart';
import 'my_courses_page.dart';
import '../create_courses/create_course.dart';
import 'dart:io';

class MyCreationsScreen extends StatefulWidget {
  final String? courseName;
  final String? courseDescription;
  final String? courseAbout;
  final String? courseImagePath;

  MyCreationsScreen({
    this.courseName,
    this.courseDescription,
    this.courseAbout,
    this.courseImagePath,
  });

  @override
  _MyCreationsScreenState createState() => _MyCreationsScreenState();
}

class _MyCreationsScreenState extends State<MyCreationsScreen> {
  int _selectedIndex = 2; // установите начальный индекс вкладки "Преподавание"
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    if (widget.courseName != null && widget.courseDescription != null && widget.courseAbout != null) {
      _addCourse(widget.courseName!, widget.courseDescription!, widget.courseAbout!, widget.courseImagePath);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MusicCoursesScreen()),
        );
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCoursesScreen()),
        );
      } else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      }
    });
  }

  void _addCourse(String courseName, String courseDescription, String courseAbout, String? courseImagePath) {
    setState(() {
      _courses.add({
        'name': courseName,
        'description': courseDescription,
        'about': courseAbout,
        'image': courseImagePath != null ? File(courseImagePath) : null,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Мои творения'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(height: 16.0),
            if (_courses.isEmpty)
              Text(
                'Здесь будут храниться созданные вами курсы',
                style: TextStyle(fontSize: 18),
              ),
            if (_courses.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 250, // Увеличиваем высоту контейнера
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF596B9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: course['image'] != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      course['image'],
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course['name'],
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              course['description'],
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              course['about'],
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Spacer(),
                ElevatedButton(
                  child: Text('Создать курс'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF48FB1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateCoursePage()),
                    );
                    if (result != null) {
                      _addCourse(result['name'], result['description'], result['about'], result['image']);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu, color: Colors.white),
            label: 'Каталог',
            backgroundColor: Color(0xFFF48FB1),
            activeIcon: Icon(Icons.menu, color: Colors.black),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border, color: Colors.white),
            label: 'Мои курсы',
            backgroundColor: Color(0xFFF48FB1),
            activeIcon: Icon(Icons.favorite_border, color: Colors.black),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage_outlined, color: Colors.white),
            label: 'Преподавание',
            backgroundColor: Color(0xFFF48FB1),
            activeIcon: Icon(Icons.storage_outlined, color: Colors.black),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.white),
            label: 'Мой профиль',
            backgroundColor: Color(0xFFF48FB1),
            activeIcon: Icon(Icons.person, color: Colors.black),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        backgroundColor: Color(0xFFF48FB1),
        onTap: _onItemTapped,
      ),
    );
  }
}
