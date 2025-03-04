import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../base/base_screen_state.dart';
import '../main_pages/music_courses_page.dart';
import '../base/bottom_navigation_moderation_utils.dart'; // Импортируем новый файл
import 'course_approval_page.dart';
import 'moderation_profile_page.dart'; // Импортируем класс Course

class ModerationPage extends StatefulWidget {
  @override
  _ModerationPageState createState() => _ModerationPageState();
}

class _ModerationPageState extends BaseScreenState<ModerationPage> {
  bool _isLoading = true;
  List<Course> _courses = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');

    if (sessionId != null) {
      try {
        final response = await http.get(
          Uri.parse('http://109.73.196.253:8001/api/moderation/'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Cookie': 'sessionid=$sessionId',
          },
        );

        if (response.statusCode == 200) {
          final rawData = utf8.decode(response.bodyBytes);
          final data = json.decode(rawData);
          setState(() {
            _courses = (data as List).map((json) => Course.fromJson(json)).toList();
          });
          print(_courses);
        } else {
          // Обработка ошибок
        }
      } catch (e) {
        // Обработка ошибок
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveCourse(int courseId) async {
    // Логика одобрения курса
  }

  Future<void> _rejectCourse(int courseId) async {
    // Логика отклонения курса
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        // MaterialPageRoute(builder: (context) => ModerationProfilePage()),
        PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ModerationPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return child;
            }
        )
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        // MaterialPageRoute(builder: (context) => ModerationProfilePage()),
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ModerationProfilePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          }
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Режим модерации'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : Center(
        child: Column(
          children: <Widget>[
            SizedBox(height: 16.0),
            if (_courses.isEmpty)
              Text(
                'Здесь будут отображаться курсы на подтверждение',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseApprovalScreen(course: course),
                          ),
                        );
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
                                                  style: TextStyle(fontSize: 15),
                                                  overflow: TextOverflow.clip,
                                                  maxLines: 3,
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // SizedBox(height: 16.0),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBarModeration(_selectedIndex, onItemTapped),
    );
  }
}
