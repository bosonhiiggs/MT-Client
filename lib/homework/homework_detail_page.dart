import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    final response = await http.get(Uri.parse('http://your-backend-url/api/homeworks/${homework.id}/answers'));

    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      return jsonResponse.map((answer) => HomeworkAnswer.fromJson(answer)).toList();
    } else {
      throw Exception('Failed to load answers');
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
          return Center(child: Text('No answers available'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final answer = snapshot.data![index];
              return ListTile(
                title: Text(answer.name),
                subtitle: Text('Файл: ${answer.filePath}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeworkAnswerDetailPage(answer: answer),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}

class HomeworkAnswer {
  final int id;
  final String name;
  final String filePath;

  HomeworkAnswer({required this.id, required this.name, required this.filePath});

  factory HomeworkAnswer.fromJson(Map<String, dynamic> json) {
    return HomeworkAnswer(
      id: json['id'],
      name: json['name'],
      filePath: json['file_path'],
    );
  }
}
