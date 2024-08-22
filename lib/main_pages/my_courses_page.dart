import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'music_courses_page.dart';
import 'my_creations_page.dart';
import 'package:http/http.dart' as http;

class Course {
  final int id;
  final String title;
  final String description;
  final String targetDescription;
  final String logo;
  final String slug;
  final String creatorUsername;
  final String createdAtFormatted;
  final bool approval;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDescription,
    required this.logo,
    required this.slug,
    required this.creatorUsername,
    required this.createdAtFormatted,
    required this.approval,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetDescription: json['target_description'] ?? '',
      logo: json['logo'] ?? '',
      slug: json['slug'] ?? '',
      creatorUsername: json['creator_username'] ?? '',
      createdAtFormatted: json['created_at_formatted'] ?? '',
      approval: json['approval'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'target_description': targetDescription,
    'logo': logo,
    'slug': slug,
    'creator_username': creatorUsername,
    'created_at_formatted': createdAtFormatted,
    'approval': approval,
  };
}

class MyCoursesScreen extends StatefulWidget {
  final Course? selectedCourse;

  MyCoursesScreen({this.selectedCourse});

  @override
  _MyCoursesScreenState createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  int _selectedIndex = 1;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    if (widget.selectedCourse != null) {
      _addSelectedCourse(widget.selectedCourse!);
    }
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await fetchCourses();
      setState(() {
        _courses = courses;
      });
    } catch (e) {
      print('Error loading courses: $e');
    }
  }

  Future<List<Course>> fetchCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');
    String? csrfToken = prefs.getString('csrftoken');

    if (sessionId != null || csrfToken != null) {
      try {
        final url = 'http://80.90.187.60:8001/api/mycourses/';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Cookie': 'sessionid=$sessionId',
          },
        );
        print(response.statusCode);

        if (response.statusCode == 200) {
          final rawData = utf8.decode(response.bodyBytes);
          final data = json.decode(rawData);
          print(data);
          final List<dynamic> results = data;
          return results.map((json) => Course.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load courses');
        }
      } catch (e) {
        print('Error: $e');
        throw Exception('Failed to load courses due to an error');
      }
    } else {
      throw Exception('SessionID или CSRF токен отсутсвуют');
    }
  }

  void _addSelectedCourse(Course course) {
    setState(() {
      _courses.add(course);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      } else if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MusicCoursesScreen()),
        );
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyCreationsScreen()),
        );
      }
    });
  }

  Future<void> _navigateToCourseDetails(BuildContext context, Course course) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('courseSlug', course.slug);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsPage(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Мои курсы'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(height: 16.0),
            if (_courses.isEmpty)
              Text(
                'Здесь будут храниться курсы, которые вы проходите',
                style: TextStyle(fontSize: 18),
              ),
            if (_courses.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return GestureDetector(
                      onTap: () {
                        _navigateToCourseDetails(context, course);
                      },
                      child: Padding(
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
                                    height: 250,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF596B9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: course.logo.isNotEmpty
                                        ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        course.logo,
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
                                        height: 200,
                                        margin: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                course.title,
                                                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                course.targetDescription,
                                                style: TextStyle(fontSize: 20),
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
                      ),
                    );
                  },
                ),
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

class CourseDetailsPage extends StatelessWidget {
  final Course course;

  CourseDetailsPage({required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Описание:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(course.description),
            SizedBox(height: 16),
            Text(
              'Цель курса:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(course.targetDescription),
            SizedBox(height: 16),
            Text(
              'Создатель:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(course.creatorUsername),
            SizedBox(height: 16),
            Text(
              'Дата создания:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(course.createdAtFormatted),
          ],
        ),
      ),
    );
  }
}
