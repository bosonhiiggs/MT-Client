import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' hide Card;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart' show VideoPlayerController, VideoPlayer, VideoProgressIndicator;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';  // для определения типа контента
import 'package:mime/mime.dart'; // для определения MIME типа файла


class LessonData {
  final String lessonName;
  final String videoPath;
  final String taskText;
  final String testQuestion;
  final String correctAnswer;
  final List<String> wrongAnswers;

  LessonData({
    required this.lessonName,
    required this.videoPath,
    required this.taskText,
    required this.testQuestion,
    required this.correctAnswer,
    required this.wrongAnswers,
  });
}

class CreateLessonPage2 extends StatefulWidget {
  final String courseSlug;
  final String courseDescription;
  final String courseAbout;
  final int moduleIndex;
  final String moduleName;
  final int lessonIndex;
  final String moduleId;
  final String lessonName;
  final String lessonId;

  CreateLessonPage2({
    required this.courseSlug,
    required this.courseDescription,
    required this.courseAbout,
    required this.moduleIndex,
    required this.moduleName,
    required this.lessonIndex,
    required this.lessonName,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  _CreateLessonPage2State createState() => _CreateLessonPage2State();
}

class _CreateLessonPage2State extends State<CreateLessonPage2> {
  final _formKey = GlobalKey<FormState>();

  String _lessonName = '';
  String _videoPath = '';
  String _taskText = '';
  String _testQuestion = '';
  String _correctAnswer = '';
  List<String> _wrongAnswers = [''];
  PlatformFile? videoFile;
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _lessonName = widget.lessonName;
    print('ID урока: ${widget.lessonId}');
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    if (videoFile != null) {
      _controller = VideoPlayerController.file(File(videoFile!.path!))
        ..initialize().then((_) {
          setState(() {});
          _controller?.play();
        });
    }
  }

  LessonData _createLessonData() {
    return LessonData(
      lessonName: _lessonName,
      videoPath: _videoPath,
      taskText: _taskText,
      testQuestion: _testQuestion,
      correctAnswer: _correctAnswer,
      wrongAnswers: _wrongAnswers,
    );
  }

  Future<void> _sendTextToServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/text/';

    final requestBody = {
      'lesson_name': _lessonName,
      'task_text': _taskText,
      'test_question': _testQuestion,
      'correct_answer': _correctAnswer,
      'wrong_answers': _wrongAnswers.where((answer) => answer.isNotEmpty).toList(),
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Text data sent successfully');
      } else {
        print('Failed to send text data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending text data: $e');
    }
  }

  Future<void> _sendVideoToServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionid');
    final csrfToken = prefs.getString('csrftoken');

    final Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
    };

    if (sessionId != null && csrfToken != null) {
      headers['Cookie'] = 'sessionid=$sessionId; csrftoken=$csrfToken';
      headers['X-CSRFToken'] = csrfToken;
    }

    final url = 'http://80.90.187.60:8001/api/mycreations/create/${widget.courseSlug}/modules/${widget.moduleId}/${widget.lessonId}/file/';

    var request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers.addAll(headers);

    // Если видео выбрано, добавляем его в multipart request
    if (videoFile != null) {
      final mimeType = lookupMimeType(videoFile!.path!);
      final video = await http.MultipartFile.fromPath(
        'video',
        videoFile!.path!,
        contentType: MediaType.parse(mimeType ?? 'video/mp4'),
      );
      request.files.add(video);

      // Логируем информацию о видео
      print('Отправляемое видео: ${videoFile!.name}, MIME: $mimeType');
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('Video sent successfully');
      } else {
        print('Failed to send video: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending video: $e');
    }
  }

  void _addWrongAnswer() {
    setState(() {
      _wrongAnswers.add('');
    });
  }

  void _removeWrongAnswer(int index) {
    setState(() {
      if (_wrongAnswers.length > 1) {
        _wrongAnswers.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Video file path: ${videoFile?.path}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Создание урока'),
        centerTitle: true,
        backgroundColor: Color(0xFFF48FB1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFF48FB1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextFormField(
                    initialValue: _lessonName,
                    onChanged: (value) {
                      setState(() {
                        _lessonName = value;
                      });
                    },
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Название урока',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Text('Прикрепите видео к уроку: '),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.file_download),
                      color: Color(0xFFF48FB1),
                      onPressed: () async {
                        final file = await FilePicker.platform.pickFiles(
                          type: FileType.video,
                        );

                        if (file != null) {
                          setState(() {
                            videoFile = file.files.first;
                          });
                          await _initializeController();
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (_controller != null && _controller!.value.isInitialized)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller!),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: VideoProgressIndicator(_controller!, allowScrubbing: true),
                        ),
                        IconButton(
                          icon: Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller!.value.isPlaying
                                  ? _controller!.pause()
                                  : _controller!.play();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              if (videoFile != null && (_controller == null || !_controller!.value.isInitialized))
                Text(
                  'Выбранное видео: ${videoFile!.name}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFF48FB1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextFormField(
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        _taskText = value;
                      });
                    },
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Текст задания',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _testQuestion = value;
                    });
                  },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Вопрос для теста',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _correctAnswer = value;
                    });
                  },
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Правильный ответ',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _wrongAnswers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            onChanged: (value) {
                              setState(() {
                                _wrongAnswers[index] = value;
                              });
                            },
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Неправильный ответ',
                              labelStyle: TextStyle(color: Colors.black),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeWrongAnswer(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: _addWrongAnswer,
                child: Text('Добавить неправильный ответ'),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Сначала отправляем текстовые данные
                      await _sendTextToServer();

                      // Затем отправляем видео, если оно выбрано
                      await _sendVideoToServer();
                    }
                  },
                  child: Text('Сохранить'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFF48FB1),
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
