import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base/base_screen_state.dart';
import '../base/bottom_navigation_utils.dart';
import '../create_courses/create_course_moduels.dart';
import '../create_courses/create_course_naming.dart';
import 'profile_page.dart';
import 'music_courses_page.dart';
import 'my_courses_page.dart';
import '../create_courses/create_course.dart';
import 'dart:io';
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
  final double rating; // Добавлено поле для рейтинга

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
    required this.rating, // Добавлено поле для рейтинга
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    double averageRating = 0.0;
    if (json['ratings'] != null && json['ratings'].isNotEmpty) {
      List<dynamic> ratings = json['ratings'];
      double totalRating = 0.0;
      for (var rating in ratings) {
        totalRating += rating['rating'] ?? 0.0;
      }
      averageRating = totalRating / ratings.length;
    }

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
      rating: averageRating, // Добавлено поле для рейтинга
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
    'rating': rating, // Добавлено поле для рейтинга
  };
}

class MyCreationsScreen extends StatefulWidget {
  @override
  _MyCreationsScreenState createState() => _MyCreationsScreenState();
}

class _MyCreationsScreenState extends BaseScreenState<MyCreationsScreen> {
  int _selectedIndex = 2; // установите начальный индекс вкладки "Преподавание"
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
        final url = 'http://80.90.187.60:8001/api/mycreations/';
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

  Future<void> _navigateToCreateCoursePage3(BuildContext context, Course course) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('courseSlug', course.slug);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCoursePage3(
          courseDescription: course.description,
          courseAbout: course.targetDescription,
          courseName: course.title,
          courseImagePath: course.logo,
        ),
      ),
    );
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
          automaticallyImplyLeading: false,
          title: Text('Мои творения'),
          centerTitle: true,
          backgroundColor: Color(0xFFF48FB1),
          actions: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.black),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateCoursePage()),
                );
                if (result != null) {
                  setState(() {
                    _courses.add(Course(
                      id: 0,
                      // Temporary ID
                      title: result['name'],
                      description: result['description'],
                      targetDescription: result['targetDescription'],
                      logo: result['image'] ?? '',
                      slug: result['slug'] ?? '',
                      creatorUsername: 'you',
                      createdAtFormatted: 'Now',
                      approval: false,
                      rating: 0.0, // Temporary rating
                    ));
                  });
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            children: <Widget>[

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
                      return GestureDetector(
                        onTap: () {
                          _navigateToCreateCoursePage3(context, course);
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
