import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'homework_detail_page.dart';

class HomeworkCheckPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Проверка домашних заданий'),
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: HomeworkList(),
    );
  }
}

class HomeworkList extends StatelessWidget {

  Future<List<Homework>> fetchHomeworks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');
    String? csrfToken = prefs.getString('csrftoken');

    if (sessionId != null || csrfToken != null) {
      try {
        final url = 'http://109.73.196.253:8001/api/mycreations/tasks/';
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

          final List jsonResponse = data;
          return jsonResponse.map((homework) => Homework.fromJson(homework)).toList();
        } else {
          throw Exception('Failed to load homework');
        }
      } catch (e) {
        print('Error: $e');
        throw Exception('Failed to load homework to an error');
      }
    } else {
      throw Exception('SessionID или CSRF токен отсутсвуют');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Homework>>(
      future: fetchHomeworks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No homeworks available'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final homework = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    homework.courseTitle + " - " + homework.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeworkDetailPage(homework: homework),),
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
}

class Homework {
  final int id;
  final String title;
  final String courseTitle;

  Homework({required this.id, required this.title, required this.courseTitle});

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'],
      title: json['title'],
      courseTitle: json['course_title'],
    );
  }
}
