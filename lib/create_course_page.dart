import 'package:flutter/material.dart';

class CreateCoursePage extends StatefulWidget {
  @override
  _CreateCoursePageState createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создать курс'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Создавайте платные курсы для монетизации знаний',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              'Любой автор может разместить курс на продажу в рублях. Мы берём 10% на обслуживание серверов и обработку платежей',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              child: Text('Разместить платный курс'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFFF48FB1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () {
                // ваш код для размещения платного курса
              },
            ),
            SizedBox(height: 16.0),
            Text(
              'Создавайте бесплатные курсы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              'Обучайте тому, в чём вы отлично разбираетесь.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              child: Text('Разместить бесплатный курс'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFFF48FB1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateCoursePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

