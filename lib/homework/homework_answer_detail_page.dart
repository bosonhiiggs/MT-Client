import 'package:flutter/material.dart';

import 'homework_detail_page.dart';

class HomeworkAnswerDetailPage extends StatelessWidget {
  final HomeworkAnswer answer;

  HomeworkAnswerDetailPage({required this.answer});

  void _handleCorrect() {
    // Логика для обработки правильного ответа
    print('Ответ помечен как правильный');
  }

  void _handleIncorrect() {
    // Логика для обработки неправильного ответа
    print('Ответ помечен как неправильный');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ответ на домашнее задание'),
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Имя: ${answer.name}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Файл: ${answer.filePath}', style: TextStyle(fontSize: 18)),
            // Здесь можно добавить логику для отображения файла
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _handleCorrect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text('Правильно'),
                ),
                ElevatedButton(
                  onPressed: _handleIncorrect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text('Неправильно'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
