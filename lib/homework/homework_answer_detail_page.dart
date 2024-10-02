import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'homework_check_page.dart';
import 'homework_detail_page.dart';

class HomeworkAnswerDetailPage extends StatefulWidget {
  final HomeworkAnswer answer;

  HomeworkAnswerDetailPage({required this.answer});

  @override
  _HomeworkAnswerDetailPageState createState() => _HomeworkAnswerDetailPageState();
}

// class _HomeworkAnswerDetailPageState extends State<HomeworkAnswerDetailPage> {
//   Map<String, dynamic>? homeworkDetails;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchHomeworkDetails();
//   }
//
//   Future<void> fetchHomeworkDetails() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? sessionId = prefs.getString('sessionid');
//
//     final url = 'http://80.90.187.60:8001/api/mycreations/tasks/${widget.answer.taskId}/${widget.answer.id}/';
//
//     try {
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json; charset=UTF-8',
//           'Cookie': 'sessionid=$sessionId',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         setState(() {
//           homeworkDetails = json.decode(response.body);
//         });
//       } else {
//         throw Exception('Failed to load homework details');
//       }
//     } catch (e) {
//       print('Error fetching homework details: $e');
//     }
//   }
//
//   Future<void> submitAssessment(bool isCorrect) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? sessionId = prefs.getString('sessionid');
//
//     final url = 'http://80.90.187.60:8001/api/mycreations/tasks/${widget.answer.taskId}/${widget.answer.id}/';
//     final body = json.encode({
//       "is_correct": isCorrect.toString(),
//       "comment": "optional", // здесь можно добавить комментарий, если нужно
//     });
//
//     try {
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json; charset=UTF-8',
//           'Cookie': 'sessionid=$sessionId',
//         },
//         body: body,
//       );
//
//       if (response.statusCode == 200) {
//         print('Assessment submitted successfully');
//       } else {
//         throw Exception('Failed to submit assessment');
//       }
//     } catch (e) {
//       print('Error submitting assessment: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Ответ на домашнее задание'),
//         backgroundColor: Color(0xFFF48FB1),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: homeworkDetails == null
//             ? Center(child: CircularProgressIndicator())
//             : Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Файл:',
//               style: TextStyle(fontSize: 16),
//             ),
//             SizedBox(height: 5),
//             ElevatedButton(
//               onPressed: () async {
//                 final fileUrl = homeworkDetails!['file'].replaceFirst('http://80.90.187.60/', 'http://80.90.187.60:8001/');
//                 try {
//                   // Получаем директорию "Загрузки"
//                   Directory? downloadsDirectory;
//                   if (Platform.isAndroid) {
//                     downloadsDirectory = Directory('/storage/emulated/0/Download');
//                   }
//
//                   String fileName = fileUrl.split('/').last;
//                   if (downloadsDirectory != null) {
//                     String filePath = '${downloadsDirectory.path}/$fileName'; // Задайте нужное имя файла
//
//                     // Скачиваем файл
//                     await Dio().download(fileUrl, filePath);
//                     print('File downloaded to: $filePath');
//
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           title: Text('Скачивание завершено'),
//                           content: Text('Файл сохранен по пути: $filePath'),
//                           actions: [
//                             TextButton(
//                               onPressed: () {
//                                 Navigator.of(context).pop(); // Закрыть диалог
//                               },
//                               child: Text('OK'),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   }
//                 } catch (e) {
//                   print('Error downloading file: $e');
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 backgroundColor: Colors.blue, // Цвет фона
//               ),
//               child: Text(
//                 'Скачать файл',
//                 style: TextStyle(color: Colors.white), // Цвет текста
//               ),
//             ),
//             Spacer(),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: () => submitAssessment(true),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//                   ),
//                   child: Text('Правильно'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => submitAssessment(false),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//                   ),
//                   child: Text('Неправильно'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
// }

class _HomeworkAnswerDetailPageState extends State<HomeworkAnswerDetailPage> {
  Map<String, dynamic>? homeworkDetails;
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    fetchHomeworkDetails();
  }

  Future<void> fetchHomeworkDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionid');

    final url = 'http://80.90.187.60:8001/api/mycreations/tasks/${widget.answer.taskId}/${widget.answer.id}/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$sessionId',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          homeworkDetails = json.decode(response.body);
        });
        fetchUserInfo(widget.answer.student); // Загрузка информации о пользователе
      } else {
        throw Exception('Failed to load homework details');
      }
    } catch (e) {
      print('Error fetching homework details: $e');
    }
  }

  Future<void> fetchUserInfo(int userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? sessionId = prefs.getString('sessionid');

      final url = 'http://80.90.187.60:8001/api/user/$userId/';
      try {
        final response = await http.get(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=$sessionId',
          },);
        print(response.statusCode);

        if (response.statusCode == 200) {
          setState(() {
            userInfo = json.decode(utf8.decode(response.bodyBytes));
          });
        } else {
          throw Exception('Failed to load user info');
        }
      } catch (e) {
        print('Error fetching user info: $e');
      }
    } catch (e) {
      print("Error to load credentionals");
    }
  }

  Future<void> submitAssessment(bool isCorrect) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionid = prefs.getString('sessionid');
    String? csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (sessionid != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionid; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://80.90.187.60:8001/api/mycreations/tasks/${widget.answer.taskId}/${widget.answer.id}/';
    final body = json.encode({
      "is_correct": isCorrect.toString(),
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      print(response.statusCode);

      if (response.statusCode == 201) {
        print('Assessment submitted successfully');
        // Показываем уведомление о успешной отправке
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Оценка отправлена'),
              content: Text('Оценка успешно отправлена.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeworkCheckPage()), // Замените на ваш список ответов
                    );// Закрыть диалог
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to submit assessment');
      }
    } catch (e) {
      print('Error submitting assessment: $e');
      // Показываем уведомление об ошибке
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Ошибка'),
            content: Text('Не удалось отправить оценку. Попробуйте еще раз.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Закрыть диалог
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
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
        child: homeworkDetails == null || userInfo == null
            ? Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(userInfo!['avatar']),
              radius: 200, // Увеличиваем радиус аватарки
            ),
            SizedBox(height: 10),
            Text(
              userInfo!['first_name'] != null && userInfo!['last_name'] != null
                  ? '${userInfo!['first_name']} ${userInfo!['last_name']}'
                  : userInfo!['username'],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, // Центрируем текст
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final fileUrl = homeworkDetails!['file'].replaceFirst('http://80.90.187.60/', 'http://80.90.187.60:8001/');
                try {
                  Directory? downloadsDirectory;
                  if (Platform.isAndroid) {
                    downloadsDirectory = Directory('/storage/emulated/0/Download');
                  }

                  String fileName = fileUrl.split('/').last;
                  if (downloadsDirectory != null) {
                    String filePath = '${downloadsDirectory.path}/$fileName';

                    await Dio().download(fileUrl, filePath);
                    print('File downloaded to: $filePath');

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Скачивание завершено'),
                          content: Text('Файл сохранен по пути: $filePath'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                } catch (e) {
                  print('Error downloading file: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                'Скачать файл',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => submitAssessment(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text('Правильно'),
                ),
                ElevatedButton(
                  onPressed: () => submitAssessment(false),
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
