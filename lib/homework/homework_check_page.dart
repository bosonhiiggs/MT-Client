import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    final response = await http.get(Uri.parse('http://your-backend-url/api/homeworks'));

    if (response.statusCode == 200) {
      final List jsonResponse = json.decode(response.body);
      return jsonResponse.map((homework) => Homework.fromJson(homework)).toList();
    } else {
      throw Exception('Failed to load homeworks');
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
              return ListTile(
                title: Text(homework.title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeworkDetailPage(homework: homework),
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

class Homework {
  final int id;
  final String title;

  Homework({required this.id, required this.title});

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'],
      title: json['title'],
    );
  }
}
