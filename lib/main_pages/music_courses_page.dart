import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base/base_screen_state.dart';
import '../base/bottom_navigation_utils.dart';
import 'profile_page.dart';
import 'my_courses_page.dart';
import 'my_creations_page.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    List<Comment> comments = await fetchComments(course.slug);
                                    showDialog<void>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return CommentsDialog(comments: comments);
                                      },
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Color(0xFFF48FB1),
                                        size: 30,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _formatRatingForDialog(course.rating),
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _purchaseCourse(course);
                                    Navigator.of(context).pop();
                                    _navigateToMyCourses(context, course);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Color(0xFFF48FB1),
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30), // Увеличиваем радиус для овальной формы
                                    ),
                                  ),
                                  child: Text('Начать'),
                                ),
                              ],
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

  String _formatRatingForDialog(double rating) {
    if (rating % 1 == 0) {
      return '${rating.toInt()}';
    } else {
      return '${rating.toStringAsFixed(1)}';
    }
  }

  Future<void> _navigateToMyCourses(BuildContext context, Course? course) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyCoursesScreen(),
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            _showCommentsDialog(context, rating);
          },
          child: Row(
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
          ),
        ),
        SizedBox(width: 8),
        Text(
          _formatRating(rating),
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _formatRating(double rating) {
    if (rating % 1 == 0) {
      return '${rating.toInt()}/5';
    } else {
      return '${rating.toStringAsFixed(1)}/5';
    }
  }

  Widget _buildAdvertisement() {
    return GestureDetector(
      onTap: () {
        _launchEmail();
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/icons/reklama.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
            ),
          ),
        ),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'pyaninyury@yandex.ru',
    );
    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not launch email';
    }
  }

  Future<void> _showCommentsDialog(BuildContext context, double rating) async {
    // Загрузка комментариев для курса
    List<Comment> comments = await fetchComments(rating as String);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CommentsDialog(comments: comments);
      },
    );
  }

  Future<List<Comment>> fetchComments(String courseSlug) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');
    String? csrfToken = prefs.getString('csrftoken');

    if (sessionId == null || csrfToken == null) {
      throw Exception('SessionID или CSRF токен отсутсвуют');
    }

    final url = 'http://80.90.187.60:8001/api/mycourses/$courseSlug/';
    print('Fetching comments from: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$sessionId',
        },
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = json.decode(rawData);
        final comments_data = data['ratings'] ?? [];
        print('Decoded data: $comments_data');

        List<Comment> comments = [];
        for (var json in comments_data) {
          final comment = Comment.fromJson(json);
          final userInfo = await _fetchUserInfo(comment.user); // Получаем информацию о пользователе
          final firstName = userInfo.firstname.isNotEmpty ? userInfo.firstname : userInfo.username;
          final lastName = userInfo.lastname.isNotEmpty ? userInfo.lastname : '';

          comments.add(comment.copyWith(
            firstName: firstName,
            lastName: lastName,
            avatar: userInfo.avatar,
          ));
        }

        return comments;
      } else {
        throw Exception('Failed to fetch comments');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      throw Exception('Failed to fetch comments due to an error');
    }
  }

  Future<UserInfo> _fetchUserInfo(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');

    if (sessionId == null) {
      throw Exception('SessionID отсутсвует');
    }

    final url = 'http://80.90.187.60:8001/api/user/$userId/';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'sessionid=$sessionId',
      },
    );

    if (response.statusCode == 200) {
      final rawData = utf8.decode(response.bodyBytes);
      final data = json.decode(rawData);
      return UserInfo.fromJson(data);
    } else {
      throw Exception('Failed to load user info');
    }
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
            if (_courses.isEmpty)
              Text(
                'Здесь будут храниться музыкальные курсы',
                style: TextStyle(fontSize: 18),
              ),
            if (_courses.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _courses.length + (_courses.length ~/ 3), // Добавляем рекламные блоки
                  itemBuilder: (context, index) {
                    if (index % 4 == 3) {
                      return _buildAdvertisement();
                    } else {
                      final course = _courses[index - (index ~/ 4)];
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
                                                    style: TextStyle(fontSize: 15),
                                                    overflow: TextOverflow.clip,
                                                    maxLines: 3,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Spacer(),
                                                Align(
                                                  alignment: Alignment.bottomRight,
                                                  child: _buildRating(course.rating),
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
                    }
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(_selectedIndex, onItemTapped),
    );
  }
}

class Comment {
  final int id;
  final int user;
  final String firstName;
  final String lastName;
  final String avatar;
  final String review;
  final double rating;

  Comment({
    required this.id,
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required this.review,
    required this.rating,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      user: json['user'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatar: json['avatar'] ?? '',
      review: json['review'] ?? '',
      rating: json['rating']?.toDouble() ?? 0.0,
    );
  }

  Comment copyWith({
    int? id,
    int? user,
    String? firstName,
    String? lastName,
    String? avatar,
    String? review,
    double? rating,
  }) {
    return Comment(
      id: id ?? this.id,
      user: user ?? this.user,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      review: review ?? this.review,
      rating: rating ?? this.rating,
    );
  }
}

class CommentTile extends StatelessWidget {
  final Comment comment;

  CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(comment.avatar),
            radius: 24,
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comment.firstName} ${comment.lastName}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(
                  comment.review,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8.0),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      color: index < comment.rating ? Color(0xFFF48FB1) : Colors.grey,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentsDialog extends StatelessWidget {
  final List<Comment> comments;

  CommentsDialog({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
        child: Column(
          children: [
            if (comments.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Нет комментариев',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentTile(comment: comment);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UserInfo {
  final String username;
  final String firstname;
  final String lastname;
  final String email;
  final String avatar;

  UserInfo({
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.avatar,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['username'] ?? '',
      firstname: json['first_name'] ?? '',
      lastname: json['last_name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }
}
