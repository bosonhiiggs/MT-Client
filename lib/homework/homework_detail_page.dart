import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'homework_answer_detail_page.dart';
import 'homework_check_page.dart';

class HomeworkDetailPage extends StatelessWidget {
  final Homework homework;

  HomeworkDetailPage({required this.homework});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(homework.title),
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: HomeworkAnswersList(homework: homework),
    );
  }
}

class HomeworkAnswersList extends StatelessWidget {
  final Homework homework;

  HomeworkAnswersList({required this.homework});

  Future<List<HomeworkAnswer>> fetchAnswers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');
    String? csrfToken = prefs.getString('csrftoken');

    if (sessionId != null || csrfToken != null) {
      try {
        final url = 'http://10.0.2.2:8000/api/mycreations/tasks/${homework.id}/';
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
          final List jsonResponse = data;
          return jsonResponse.map((answer) => HomeworkAnswer.fromJson(answer)).toList();

        } else {
          throw Exception('Failed to load homework answers');
        }
      } catch (e) {
        print('Error: $e');
        throw Exception('Failed to load homework answers to an error');
      }
    } else {
      throw Exception('SessionID или CSRF токен отсутсвуют');
    }
  }

  Future<String> fetchStudentName(int studentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');
    if (sessionId != null) {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/user/$studentId/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$sessionId',
        },
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final userData = json.decode(rawData);
        if (userData['first_name'] != null && userData['last_name'] != null) {
          return '${userData['first_name']} ${userData['last_name']}';
        } else {
          return userData['username'];
        }
      } else {
        throw Exception('Failed to load student name');
      }
    } else {
      throw Exception('SessionID is missing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeworkAnswer>>(
      future: fetchAnswers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Нет домашнего задания на проверку'));
        } else {
          return FutureBuilder<List<String>>(
            future: Future.wait(
              snapshot.data!.map((answer) => fetchStudentName(answer.student)),
            ),
            builder: (context, namesSnapshot) {
              if (namesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (namesSnapshot.hasError) {
                return Center(child: Text('Error fetching student names: ${namesSnapshot.error}'));
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final answer = snapshot.data![index];
                    final studentName = namesSnapshot.data![index];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        title: Text('Ответ студента: $studentName'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeworkAnswerDetailPage(answer: answer),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }
}

class HomeworkAnswer {
  final int id;
  final int taskId;
  final int student;
  final String file;
  final String submittedAt;

  HomeworkAnswer({
    required this.id,
    required this.taskId,
    required this.student,
    required this.file,
    required this.submittedAt,
  });

  factory HomeworkAnswer.fromJson(Map<String, dynamic> json) {
    return HomeworkAnswer(
      id: json['id'],
      taskId: json['task'],
      student: json['student'],
      file: json['file'],
      submittedAt: json['submitted_at'],
    );
  }
}
