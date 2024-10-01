import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../base/base_screen_state.dart';
import '../main_pages/music_courses_page.dart';
import '../base/bottom_navigation_moderation_utils.dart'; // Импортируем новый файл
import 'moderation_profile_page.dart'; // Импортируем класс Course

class ModerationPage extends StatefulWidget {
  @override
  _ModerationPageState createState() => _ModerationPageState();
}

class _ModerationPageState extends BaseScreenState<ModerationPage> {
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
          Uri.parse('http://80.90.187.60:8001/api/moderation/'),
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

  Widget _buildRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(
            Icons.star,
            color: Color(0xFFF48FB1),
          );
        } else if (index == rating.floor() && rating % 1 != 0) {
          return Stack(
            children: [
              Icon(
                Icons.star,
                color: Colors.grey,
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: rating % 1,
                  child: Icon(
                    Icons.star,
                    color: Color(0xFFF48FB1),
                  ),
                ),
              ),
            ],
          );
        } else {
          return Icon(
            Icons.star,
            color: Colors.grey,
          );
        }
      }),
    );
  }

  String _formatRating(double rating) {
    if (rating % 1 == 0) {
      return '${rating.toInt()}/5';
    } else {
      return '${rating.toStringAsFixed(1)}/5';
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
      body: Center(
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
                        // Логика для просмотра курса
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
                                              SizedBox(height: 10),
                                              Spacer(),
                                              Align(
                                                alignment: Alignment.bottomRight,
                                                child: Row(
                                                  children: [
                                                    _buildRating(course.rating),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      _formatRating(course.rating),
                                                      style: TextStyle(fontSize: 14),
                                                    ),
                                                  ],
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check),
                                    onPressed: () => _approveCourse(course.id),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () => _rejectCourse(course.id),
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
            SizedBox(height: 16.0),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBarModeration(_selectedIndex, onItemTapped),
    );
  }
}
