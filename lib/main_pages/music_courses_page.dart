import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base/base_screen_state.dart';
import '../base/bottom_navigation_utils.dart';
import 'profile_page.dart';
import 'my_courses_page.dart';
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

class MusicCoursesScreen extends StatefulWidget {
  @override
  _MusicCoursesScreenState createState() => _MusicCoursesScreenState();
}

class _MusicCoursesScreenState extends BaseScreenState<MusicCoursesScreen> {
  int _selectedIndex = 0;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
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
        final url = 'http://80.90.187.60:8001/api/catalog/';
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

  Future<void> _purchaseCourse(Course course) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');
    String? csrfToken = prefs.getString('csrftoken');

    print(sessionId);
    print(csrfToken);

    if (sessionId == null || csrfToken == null ) {
      print('SessionID или CSRF токен отсутсвуют');
      return;
    }

    final url = 'http://80.90.187.60:8001/api/catalog/${course.slug}/';

    try {

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sessionid=$sessionId; csrftoken=$csrfToken',
          'X-CSRFToken': csrfToken,
        },
        body: json.encode({}),
      );

      print(response.headers['Cookie']);

      if (response.statusCode == 200) {
        print('Курс успешно приобретен');
      } else {
        print('Ошибка при покупке курса: ${response.statusCode}');
      }

    } catch (e) {
      print('Ошибка: $e');
    }

    }

  Future<void> _showStartCourseDialog(BuildContext context, Course course) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
            child: Stack(
              children: [
                course.logo.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    course.logo,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
                    : Center(
                  child: Icon(
                    Icons.photo,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
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
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      course.targetDescription,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      course.description,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _purchaseCourse(course);
                                  Navigator.of(context).pop();
                                  // try {
                                  //   // await _purchaseCourse(course);
                                  //   if (mounted) {
                                  //     _navigateToMyCourses(context, course);
                                  //   }
                                  // } catch (e) {
                                  //   print('Ошибка при создании курса: $e');
                                  // }
                                  // await _purchaseCourse(course);
                                  _navigateToMyCourses(context, course);
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Color(0xFFF48FB1),
                                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30), // Увеличиваем радиус для овальной формы
                                  ),
                                ),
                                child: Text('Начать'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToMyCourses(BuildContext context, Course? course) async {
     Navigator.push(
       context,
      MaterialPageRoute(
         builder: (context) => MyCoursesScreen(),
       ),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Музыкальные курсы'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(height: 16.0),
            if (_courses.isEmpty)
              Text(
                'Здесь будут храниться музыкальные курсы',
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
                        _showStartCourseDialog(context, course);
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
                                              Flexible(
                                                child: Text(
                                                  course.targetDescription,
                                                  style: TextStyle(fontSize: 20),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 3,
                                                ),
                                              ),
                                              SizedBox(height: 10),
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
        bottomNavigationBar: buildBottomNavigationBar(_selectedIndex, onItemTapped)
    );
  }
}
